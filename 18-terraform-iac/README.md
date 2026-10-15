# Session 18 – Terraform & Infrastructure as Code

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

This session had two parts: a hands-on Terraform project that creates an S3 bucket, and a research part where I studied five core AWS services and wrote notes for each one.

## Folder structure

```text
18-terraform-iac/
├── terraform-s3-demo/       # Task 1 – S3 bucket with Terraform
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── terraform.tfvars
│   └── README.md            # full init → destroy workflow
└── aws-services/            # Task 2 – AWS research notes
    ├── 01-iam/README.md
    ├── 02-ec2/README.md
    ├── 03-s3/README.md
    ├── 04-vpc/README.md
    └── 05-dynamodb-rds/README.md
```

## Task 1: Terraform S3 Demo

See [`terraform-s3-demo/README.md`](terraform-s3-demo/README.md)

The project creates one S3 bucket (`vansh-24bcs10268-terraform-s3-demo`) with versioning, server-side encryption and public access blocked. I ran all eight commands (`init`, `fmt`, `validate`, `plan`, `apply`, `show`, `output`, `destroy`) and documented each one.

## Task 2: AWS Services Research

| # | Service | Category | Notes |
| :-- | :--- | :--- | :--- |
| 01 | IAM | Governance / Security | [`aws-services/01-iam`](aws-services/01-iam/README.md) |
| 02 | EC2 | Compute | [`aws-services/02-ec2`](aws-services/02-ec2/README.md) |
| 03 | S3 | Storage | [`aws-services/03-s3`](aws-services/03-s3/README.md) |
| 04 | VPC | Networking | [`aws-services/04-vpc`](aws-services/04-vpc/README.md) |
| 05 | DynamoDB & RDS | Database | [`aws-services/05-dynamodb-rds`](aws-services/05-dynamodb-rds/README.md) |

## My notes on Infrastructure as Code

**Infrastructure as Code (IaC)** means writing your servers, networks, buckets etc. as code files instead of creating them by hand in a web console.

Why it's useful:

- **Repeatable** – I can create the exact same setup again (dev, test, prod) by running one command.
- **Version controlled** – the `.tf` files live in Git, so every change has a history and can be reviewed in a PR.
- **No "it works on my account" problem** – the code is the documentation of the infra.
- **Easy cleanup** – `terraform destroy` removes everything, nothing gets forgotten.

### Key Terraform terms

| Term | Meaning |
| :--- | :--- |
| Provider | Plugin that talks to a platform's API (AWS, Azure, GCP, Kubernetes…). |
| Resource | One piece of infrastructure, e.g. `aws_s3_bucket`. |
| Variable | Input value so the code is reusable. |
| Output | Value printed after apply (IP, ARN, URL…). |
| State | `terraform.tfstate` – Terraform's record of what it manages. |
| Plan | A dry run showing what will change. |

### Declarative vs imperative

- **Imperative** (bash script / AWS CLI): "create a bucket, then enable versioning, then…". If you run it twice it may fail or create duplicates.
- **Declarative** (Terraform): "there should be one bucket with versioning on". Terraform compares this with the real world and only does what is missing. Running `apply` twice is safe.
