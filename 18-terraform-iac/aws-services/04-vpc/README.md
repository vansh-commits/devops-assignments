# Session 18 – AWS VPC (Networking)

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

## What is VPC?

A **VPC (Virtual Private Cloud)** is your own **private, isolated network** inside AWS. You decide the IP range, create subnets, control routing and firewalls – just like a network in a real data centre, but software-defined.

- A VPC belongs to **one region** but spans **all Availability Zones** in that region.
- Every account has a **default VPC** in each region (so you can launch EC2 quickly), but for real projects you create your own.
- Resources like EC2, RDS, EKS nodes and Lambda (optionally) live inside a VPC.

```text
Region: ap-south-1
└── VPC 10.0.0.0/16
    ├── AZ ap-south-1a
    │   ├── Public subnet  10.0.1.0/24  → web server / load balancer
    │   └── Private subnet 10.0.11.0/24 → app server
    └── AZ ap-south-1b
        ├── Public subnet  10.0.2.0/24
        └── Private subnet 10.0.12.0/24 → database
```

## CIDR

**CIDR (Classless Inter-Domain Routing)** is the notation for an IP range: `IP/prefix`.

- The **prefix** says how many bits are fixed for the network. The rest are for hosts.
- Number of addresses = 2^(32 − prefix).

| CIDR | Addresses | Typical use |
| :--- | :--- | :--- |
| `10.0.0.0/16` | 65,536 | whole VPC |
| `10.0.1.0/24` | 256 | one subnet |
| `10.0.1.0/28` | 16 | smallest allowed subnet |
| `0.0.0.0/0` | everything | "the internet" in route tables / SG rules |
| `203.0.113.5/32` | 1 | a single IP (e.g. my laptop for SSH) |

- VPC size must be between **/16 and /28**.
- Use private ranges (RFC 1918): `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.
- AWS **reserves 5 IPs** in every subnet (network address, VPC router, DNS, future use, broadcast), so a /24 gives 251 usable IPs.
- Plan CIDRs so they **don't overlap** with other VPCs or your office network if you want to connect them later (peering/VPN).

## Subnets

A **subnet** is a smaller range of IPs inside the VPC, and it lives in **exactly one AZ**.

- To be highly available, create subnets in at least two AZs.
- A subnet is "public" or "private" only because of its **route table** (see below).
- Setting `map_public_ip_on_launch = true` gives instances a public IP automatically.

## Route tables

A **route table** is a set of rules that decides **where network traffic goes** from a subnet.

- Every VPC has a **main route table**; you can create custom ones.
- Each subnet is associated with exactly one route table.
- Every route table has a `local` route for the VPC CIDR so all subnets can talk to each other.

Public route table:

| Destination | Target |
| :--- | :--- |
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | igw-xxxx (Internet Gateway) |

Private route table:

| Destination | Target |
| :--- | :--- |
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | nat-xxxx (NAT Gateway) |

## Internet Gateway (IGW)

An **Internet Gateway** connects the VPC to the internet.

- One IGW per VPC; it's horizontally scaled and highly available (managed by AWS).
- Allows **two-way** traffic: inbound from the internet and outbound to it.
- For an instance to be reachable it needs: IGW attached + route `0.0.0.0/0 → igw` + a public IP + security group allowing the port.

## NAT Gateway

A **NAT Gateway** lets instances in a **private subnet** reach the internet (e.g. to download updates or call external APIs) **without** being reachable from the internet.

- Placed in a **public subnet**, with an **Elastic IP**.
- Private route table sends `0.0.0.0/0 → NAT gateway`.
- **Outbound only** – connections can't be started from outside.
- Managed and AZ-specific – for HA, one NAT GW per AZ.
- **Costs money** per hour + per GB (not free tier), so I'd delete it after a demo.
- Old alternative: NAT instance (an EC2 you manage yourself).

## Security Groups

**Security groups** are firewalls at the **instance / network-interface level**.

- **Allow rules only**.
- **Stateful** – return traffic is automatically allowed.
- All rules are evaluated together.
- Can reference other security groups as source (e.g. DB SG allows 5432 only from App SG).

## Network ACLs (NACLs)

**Network ACLs** are firewalls at the **subnet level**.

- Have both **allow and deny** rules.
- **Stateless** – you must allow the return traffic explicitly (ephemeral ports 1024–65535).
- Rules are **numbered** and evaluated **in order**; first match wins.
- Default NACL allows everything; a new custom NACL denies everything.
- Good for blocking a specific bad IP range for a whole subnet.

### Security Group vs NACL

| | Security Group | Network ACL |
| :--- | :--- | :--- |
| Level | instance (ENI) | subnet |
| Rules | allow only | allow + deny |
| State | **stateful** | **stateless** |
| Evaluation | all rules together | in number order, first match |
| Applies to | only instances that use it | everything in the subnet |
| Typical use | main firewall | extra layer / blocking IPs |

## Public vs Private subnet

| | Public subnet | Private subnet |
| :--- | :--- | :--- |
| Route to internet | `0.0.0.0/0 → Internet Gateway` | `0.0.0.0/0 → NAT Gateway` (or no internet at all) |
| Public IP on instances | yes | no |
| Reachable from internet | yes (if SG allows) | **no** |
| Can reach internet | yes | outbound only (through NAT) |
| What goes here | load balancers, bastion host, NAT gateway | app servers, databases, caches |

The standard pattern is a **3-tier architecture**: ALB in public subnets → app servers in private subnets → database in private (isolated) subnets.

## Other VPC features (short notes)

- **VPC Peering** – connect two VPCs privately (non-transitive).
- **Transit Gateway** – hub to connect many VPCs and on-prem networks.
- **VPC Endpoints** – reach S3/DynamoDB/other AWS services privately without going through the internet/NAT.
- **VPC Flow Logs** – log IP traffic for debugging and security.
- **Site-to-Site VPN / Direct Connect** – connect to an office/data centre.

## Example CLI

```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16
aws ec2 create-subnet --vpc-id vpc-xxxx --cidr-block 10.0.1.0/24 --availability-zone ap-south-1a
aws ec2 create-internet-gateway
aws ec2 attach-internet-gateway --vpc-id vpc-xxxx --internet-gateway-id igw-xxxx
aws ec2 describe-vpcs --output table
```

In Session 19 I built this exact setup (VPC → public subnet → IGW → route table → SG → EC2) with Terraform.
