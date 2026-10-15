# Session 18 – DynamoDB & RDS (Database Services)

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

AWS has two main managed database services: **DynamoDB** (NoSQL) and **RDS** (relational/SQL). "Managed" means AWS handles the hardware, patching, backups and replication – I just use the database.

---

# Part 1: DynamoDB

## What is DynamoDB?

**Amazon DynamoDB** is a fully managed, **serverless NoSQL key-value and document database**. It gives single-digit millisecond performance at any scale.

- No servers to manage, no patching, no storage to provision.
- Data is automatically replicated across 3 AZs.
- Two capacity modes: **On-Demand** (pay per request) and **Provisioned** (set read/write capacity units, can auto scale).
- Free tier: 25 GB storage + enough capacity for small apps.

## NoSQL

**NoSQL** = "not only SQL". Instead of fixed tables with joins, data is stored in flexible formats (key-value, documents, wide-column, graph).

| | Relational (SQL) | NoSQL (DynamoDB) |
| :--- | :--- | :--- |
| Schema | fixed, defined upfront | flexible – each item can have different attributes |
| Joins | yes | no – you design data for your access patterns |
| Scaling | mostly vertical (bigger machine) | horizontal (partitions), virtually unlimited |
| Query language | SQL | API calls (GetItem, Query, Scan) / PartiQL |
| Best for | complex queries, transactions, reporting | huge scale, simple fast lookups |

## Tables

A **table** is a collection of items (like a table in SQL, but without a fixed schema). The only thing you must define when creating it is the **primary key**.

## Items

An **item** is a single record in a table (like a row). Max size **400 KB**.

## Attributes

An **attribute** is a single field of an item (like a column), e.g. `name`, `email`. Different items in the same table can have different attributes. Types include String, Number, Boolean, List, Map, Set, Binary.

Example item (JSON):

```json
{
  "student_id": "24bcs10268",
  "course": "DEVOPS-101",
  "name": "Vansh Malhotra",
  "grade": "A",
  "skills": ["docker", "kubernetes", "terraform"]
}
```

## Partition key

The **partition key** (also called hash key) is the main part of the primary key.

- DynamoDB hashes the value to decide **which physical partition** stores the item.
- If the table only has a partition key, it must be **unique** per item.
- Choose a key with **many distinct values** (e.g. `user_id`), so traffic spreads evenly. A bad key like `country` causes "hot partitions".

## Sort key

The **sort key** (range key) is the optional second part of the primary key.

- Partition key + sort key together must be unique (a **composite primary key**).
- Items with the same partition key are stored together, **sorted** by the sort key.
- Lets you do range queries: `begins_with`, `between`, `>`, `<`.

Example: table `Enrollments` with partition key `student_id` and sort key `course` → I can get all courses of one student, or courses starting with `DEVOPS`.

```bash
aws dynamodb create-table \
  --table-name Enrollments \
  --attribute-definitions AttributeName=student_id,AttributeType=S AttributeName=course,AttributeType=S \
  --key-schema AttributeName=student_id,KeyType=HASH AttributeName=course,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST

aws dynamodb put-item --table-name Enrollments \
  --item '{"student_id":{"S":"24bcs10268"},"course":{"S":"DEVOPS-101"},"grade":{"S":"A"}}'

aws dynamodb query --table-name Enrollments \
  --key-condition-expression "student_id = :s" \
  --expression-attribute-values '{":s":{"S":"24bcs10268"}}'
```

Extra features: **GSI/LSI** (secondary indexes to query by other attributes), **TTL** (auto-delete old items), **DynamoDB Streams** (trigger Lambda on changes), **Global Tables** (multi-region), point-in-time recovery.

## DynamoDB use cases

- User sessions, shopping carts, user profiles.
- Gaming leaderboards and player state.
- IoT and time-series event data.
- Serverless apps (API Gateway + Lambda + DynamoDB).
- Metadata store / key-value lookups at huge scale.
- Terraform state locking (the classic `terraform-locks` table).

---

# Part 2: RDS

## Relational database

A **relational database** stores data in **tables with rows and columns** and a **fixed schema**. Tables are linked using **primary keys and foreign keys**, and you query them with **SQL**, including joins. It supports **ACID transactions** (all-or-nothing, consistent), which is important for things like payments.

**Amazon RDS (Relational Database Service)** is a managed service that runs these databases for you. AWS handles: provisioning, OS + DB patching, backups, failover, monitoring. You still design the schema and write queries.

## Supported engines

- **Amazon Aurora** (MySQL- and PostgreSQL-compatible, AWS's own high-performance engine)
- **MySQL**
- **PostgreSQL**
- **MariaDB**
- **Oracle**
- **Microsoft SQL Server**
- **IBM Db2**

## DB instances

A **DB instance** is the isolated database server running in the cloud. You choose:

- **Instance class** – CPU/RAM, e.g. `db.t3.micro` / `db.t4g.micro` (free tier), `db.m6g.large`, `db.r6g.xlarge` (memory optimised).
- **Storage** – gp3 SSD, io1/io2 provisioned IOPS; storage autoscaling can grow it automatically.
- **VPC, subnet group, security group** – where it lives and who can connect.
- **Endpoint** – a DNS name you connect to, e.g. `mydb.xxxx.ap-south-1.rds.amazonaws.com:5432`.

You don't get SSH access to the underlying OS (except RDS Custom).

```bash
aws rds create-db-instance \
  --db-instance-identifier vansh-demo-db \
  --engine postgres \
  --db-instance-class db.t3.micro \
  --allocated-storage 20 \
  --master-username dbadmin \
  --manage-master-user-password \
  --no-publicly-accessible
```

## Security

- **Network isolation** – put RDS in **private subnets**, set "Publicly accessible = No".
- **Security groups** – allow the DB port (3306/5432) only from the app servers' security group.
- **Encryption at rest** with KMS (must be chosen at creation; covers storage, backups, snapshots, replicas).
- **Encryption in transit** with SSL/TLS.
- **Authentication** – master user, **IAM database authentication**, or Kerberos/AD.
- **Secrets Manager** to store and auto-rotate the master password (`--manage-master-user-password`).
- **Audit/monitoring** – CloudWatch, Performance Insights, Enhanced Monitoring, DB logs.

## Backups

- **Automated backups** – daily snapshot + transaction logs, kept 1–35 days. Enables **point-in-time recovery** (restore to any second in the retention window).
- **Manual snapshots** – taken whenever you want, kept until you delete them. Can be copied to other regions/accounts.
- Restoring always creates a **new** DB instance.

## Multi-AZ

**Multi-AZ** is for **high availability**, not performance.

- AWS keeps a **standby replica** in another AZ with **synchronous** replication.
- If the primary fails (or during maintenance), RDS **automatically fails over** to the standby, usually in 1–2 minutes; the endpoint DNS stays the same.
- The standby **cannot serve reads** in classic Multi-AZ (a Multi-AZ *DB cluster* with 2 readable standbys also exists).

## Read replicas

**Read replicas** are for **read scaling (performance)**.

- **Asynchronous** copies of the primary (so tiny lag is possible).
- Each replica has its **own endpoint**; the app sends read queries (reports, analytics) there.
- Up to 15 replicas (MySQL, MariaDB, PostgreSQL); can be **cross-region**.
- Can be **promoted** to a standalone DB (useful for DR).

### Multi-AZ vs Read Replica

| | Multi-AZ | Read Replica |
| :--- | :--- | :--- |
| Goal | high availability / failover | read performance / scaling |
| Replication | synchronous | asynchronous |
| Readable? | no (classic) | yes |
| Failover | automatic | manual promote |
| Region | same region | same or cross-region |

## RDS use cases

- Backend database for web and mobile apps (users, orders, products).
- E-commerce and banking/payment systems that need ACID transactions.
- ERP, CRM and other business apps.
- Reporting where complex joins and SQL are needed.
- Lift-and-shift of existing MySQL/PostgreSQL/Oracle/SQL Server databases to the cloud.

---

## DynamoDB vs RDS – when to use which

| Question | Choose |
| :--- | :--- |
| Data has lots of relationships, need joins / complex SQL | **RDS** |
| Need strong multi-table transactions & reporting | **RDS** |
| Huge scale, simple key lookups, millisecond latency | **DynamoDB** |
| Spiky / unpredictable traffic, serverless app | **DynamoDB** (on-demand) |
| Schema changes often, flexible attributes | **DynamoDB** |
| Existing app already uses MySQL/Postgres | **RDS** |
