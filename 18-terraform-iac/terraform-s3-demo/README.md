# Session 18 – Terraform S3 Demo

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

In this task I created an AWS S3 bucket using Terraform instead of clicking around in the AWS console. I went through the full Terraform workflow from `init` to `destroy` and captured the output of every step.

## Project structure

```text
terraform-s3-demo/
├── provider.tf        # which provider (AWS) + version, and the region
├── variables.tf       # input variables (region, bucket name, environment)
├── main.tf            # the actual resources (bucket + versioning + encryption + public access block)
├── outputs.tf         # values printed after apply (name, ARN, region)
├── terraform.tfvars   # my values for the variables
└── README.md
```

## What each file does

| File | Purpose |
| :--- | :--- |
| `provider.tf` | Tells Terraform to download the `hashicorp/aws` provider (v5.x) and use the region from `var.aws_region`. |
| `variables.tf` | Declares the inputs so nothing is hard-coded in `main.tf`. `bucket_name` has no default, so it must come from tfvars. |
| `main.tf` | Creates the bucket and three extra settings: versioning ON, AES256 encryption, and all public access blocked. |
| `outputs.tf` | Prints the bucket name, ARN and region after `apply`. |
| `terraform.tfvars` | My actual values. Bucket name is `vansh-24bcs10268-terraform-s3-demo` (S3 names are global, so I added my roll number to keep it unique). |

I also set `force_destroy = true` so that `terraform destroy` can delete the bucket even if there are test objects inside it.

## Prerequisites

- An AWS account (free tier is enough – S3 has 5 GB free for 12 months).
- AWS CLI installed (`brew install awscli`) and configured with my own IAM user keys:
  ```bash
  aws configure          # access key, secret key, region = ap-south-1, output = json
  aws sts get-caller-identity   # check that the credentials work
  ```
- Terraform installed (`brew install terraform`, check with `terraform -version`).

> Credentials are **never** written in `.tf` files. Terraform reads them from `~/.aws/credentials` automatically.  
> Always run `terraform destroy` at the end so nothing keeps costing money.

---

## Terraform workflow

All commands are run inside the `terraform-s3-demo/` folder.

### 1. `terraform init`

Initialises the working directory. It downloads the AWS provider plugin into `.terraform/` and creates `.terraform.lock.hcl` to lock the provider version.

```bash
terraform init
```

### 2. `terraform fmt`

Formats all `.tf` files into the standard Terraform style (indentation, aligned `=`). If it prints nothing, the files were already formatted.

```bash
terraform fmt
terraform fmt -check   # only checks, useful in CI
```

### 3. `terraform validate`

Checks the syntax and that all references are correct (e.g. `aws_s3_bucket.demo.id` actually exists). It does not call AWS.

```bash
terraform validate
```

### 4. `terraform plan`

Shows a preview of what Terraform will do. Here it should say **4 to add** (bucket, versioning, encryption, public access block). Nothing is created yet.

```bash
terraform plan
```

### 5. `terraform apply`

Actually creates the resources in AWS. It shows the plan again and asks for `yes`. After it finishes it prints the outputs and writes `terraform.tfstate`.

```bash
terraform apply
# type: yes
```

Then I checked in the AWS console that the bucket really exists (S3 → Buckets), and opened the **Properties** tab to see versioning and encryption enabled.

Optional check from the CLI:

```bash
aws s3 ls | grep vansh-24bcs10268
aws s3api get-bucket-versioning --bucket vansh-24bcs10268-terraform-s3-demo
```

### 6. `terraform show`

Prints the current state – every attribute of every resource Terraform is managing (ARN, region, tags, etc.).

```bash
terraform show
```

### 7. `terraform output`

Prints only the output values. Handy for scripts (`terraform output -raw bucket_name`).

```bash
terraform output
terraform output -raw bucket_name
```

### 8. `terraform destroy`

Deletes everything Terraform created, so I don't get billed. Again it asks for `yes`.

```bash
terraform destroy
# type: yes
```

---

## Summary of the workflow

```text
init → fmt → validate → plan → apply → show / output → destroy
```

| Command | Talks to AWS? | Changes anything? |
| :--- | :---: | :---: |
| `init` | No (downloads provider) | No |
| `fmt` | No | Only formats files |
| `validate` | No | No |
| `plan` | Yes (reads) | No |
| `apply` | Yes | **Creates/updates** |
| `show` / `output` | No (reads state) | No |
| `destroy` | Yes | **Deletes** |

## What I learned

- Terraform is **declarative** – I only wrote *what* I want (a private, encrypted, versioned bucket) and Terraform figured out *how* to create it.
- The **state file** (`terraform.tfstate`) is how Terraform remembers what it created. It should not be committed to Git (it can contain sensitive data), so it's in `.gitignore`.
- Since AWS provider v4, bucket settings like versioning and encryption are **separate resources** that reference the bucket, which makes the dependency graph clear.
- `plan` before `apply` is like a safety check – you always see the changes before they happen.
