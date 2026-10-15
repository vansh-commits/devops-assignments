# Session 18 – AWS EC2 (Compute)

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

## What is EC2?

**EC2 (Elastic Compute Cloud)** gives you virtual machines (called **instances**) in the AWS cloud. You choose the OS, CPU, RAM, disk and network, and you can start or stop them in minutes. You pay only while it's running (per second for Linux).

It's basically "renting a server" without buying hardware. "Elastic" means you can scale up/down or add/remove servers whenever you want.

## AMI (Amazon Machine Image)

An **AMI** is the template used to launch an instance. It contains:

- the operating system (Amazon Linux, Ubuntu, Windows, RHEL…)
- any pre-installed software
- the root volume snapshot and launch permissions

Types:

- **AWS-provided** (e.g. Amazon Linux 2023, Ubuntu 24.04)
- **Marketplace** (pre-configured images from vendors)
- **Custom AMI** – you set up an instance the way you like and create your own image (useful for "golden images" in Auto Scaling).

AMIs are **region-specific** – an AMI ID in `ap-south-1` is different from `us-east-1`. That's why in Terraform I use a `data "aws_ami"` block to look up the latest one instead of hard-coding the ID.

## Instance types

The instance type decides how much **CPU, memory, storage and network** you get. Name format:

```text
t3.micro
│││  └── size (nano, micro, small, medium, large, xlarge, 2xlarge…)
││└───── extra features (g = Graviton/ARM, d = local NVMe, n = network…)
│└────── generation
└─────── family
```

| Family | Optimised for | Example use |
| :--- | :--- | :--- |
| **T** (t3, t4g) | Burstable general purpose | small web apps, dev/test (t2/t3.micro is free tier) |
| **M** (m6i, m7g) | Balanced general purpose | app servers, backends |
| **C** (c6i, c7g) | Compute | batch processing, gaming servers, encoding |
| **R / X** | Memory | in-memory DBs, caching, big data |
| **I / D** | Storage (fast local disk) | NoSQL DBs, data warehousing |
| **P / G / Inf** | Accelerated (GPU) | ML training/inference, graphics |

## Key pairs

A **key pair** is used to securely **SSH** into a Linux instance.

- AWS keeps the **public key** and puts it on the instance (`~/.ssh/authorized_keys`).
- You download the **private key** (`.pem`) once – AWS doesn't store it, so if you lose it you can't get it back.

```bash
aws ec2 create-key-pair --key-name vansh-key --query 'KeyMaterial' --output text > vansh-key.pem
chmod 400 vansh-key.pem
ssh -i vansh-key.pem ec2-user@<public-ip>
```

Alternative without keys: **EC2 Instance Connect** or **SSM Session Manager** (no port 22 needed).

## Security Groups

A **security group** is a **virtual firewall at the instance level**.

- Only has **allow** rules (no deny rules).
- **Stateful** – if inbound traffic is allowed, the reply is automatically allowed out.
- By default: all inbound blocked, all outbound allowed.
- Rules can reference another security group (e.g. "allow port 3306 only from the web-server SG").

Example rules for a web server:

| Type | Port | Source |
| :--- | :--- | :--- |
| HTTP | 80 | 0.0.0.0/0 |
| HTTPS | 443 | 0.0.0.0/0 |
| SSH | 22 | my IP only (x.x.x.x/32) |

## EBS (Elastic Block Store)

**EBS** volumes are network-attached **disks** for EC2.

- **Persistent** – data survives stopping the instance (unlike instance store).
- Lives in **one Availability Zone**, attached to an instance in the same AZ.
- Can take **snapshots** (backups stored in S3), which can be copied to other regions.
- Can be resized and encrypted.

| Volume type | Kind | Use |
| :--- | :--- | :--- |
| gp3 / gp2 | General purpose SSD | boot volumes, most apps (default) |
| io2 / io1 | Provisioned IOPS SSD | big databases needing high IOPS |
| st1 | Throughput HDD | big sequential data, logs |
| sc1 | Cold HDD | rarely accessed data, cheapest |

**Instance store** = temporary disk physically on the host; very fast but data is lost when the instance stops.

## Public vs Private IP

| | Private IP | Public IP | Elastic IP |
| :--- | :--- | :--- | :--- |
| Reachable from | inside the VPC only | the internet | the internet |
| Assigned | always, from the subnet CIDR | if subnet/launch setting enables it | you allocate it manually |
| Changes on stop/start? | No | **Yes**, a new one is given | No (static) |
| Cost | Free | charged per hour (since 2024) | charged per hour |

So if I need a fixed address for a server, I use an **Elastic IP**, or better, put it behind a **Load Balancer** with a DNS name.

## Instance lifecycle

```text
          launch
            │
            ▼
        [pending] ──► [running] ──stop──► [stopping] ──► [stopped]
                        │   ▲                              │
                        │   └────────────start─────────────┘
                     reboot (stays running)
                        │
                    terminate
                        ▼
                [shutting-down] ──► [terminated]
```

| State | Billed for compute? | Notes |
| :--- | :---: | :--- |
| pending | No | booting |
| running | **Yes** | usable |
| stopping / stopped | No (EBS still billed) | can start again, public IP changes |
| hibernated | No | RAM saved to EBS, faster resume |
| terminated | No | gone permanently; root EBS deleted by default |

## Pricing models (bonus)

- **On-Demand** – pay per second, no commitment.
- **Reserved Instances / Savings Plans** – 1 or 3 year commitment, up to ~70% cheaper.
- **Spot** – unused capacity, up to ~90% cheaper but AWS can take it back with 2 min notice.
- **Dedicated Hosts** – a whole physical server for you (licensing/compliance).

## Common use cases

- Hosting web servers and backend APIs.
- Running CI/CD build agents (e.g. self-hosted GitHub runners, Jenkins).
- Running databases or software that isn't available as a managed service.
- Batch jobs, data processing, ML training (GPU instances).
- Kubernetes worker nodes (EKS node groups are EC2 instances).
- Dev/test environments that can be stopped at night to save money.

## Useful CLI commands

```bash
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress]' --output table
aws ec2 stop-instances --instance-ids i-0123456789abcdef0
aws ec2 start-instances --instance-ids i-0123456789abcdef0
aws ec2 terminate-instances --instance-ids i-0123456789abcdef0
```
