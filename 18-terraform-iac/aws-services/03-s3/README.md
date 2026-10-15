# Session 18 – AWS S3 (Storage)

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

## What is S3?

**S3 (Simple Storage Service)** is AWS's **object storage**. You can store any amount of files (images, videos, backups, logs, static websites) and access them over HTTP(S) from anywhere.

Key facts:

- Virtually **unlimited** storage; a single object can be up to **5 TB**.
- Designed for **99.999999999% (11 nines) durability** – data is copied across multiple Availability Zones.
- You pay for storage used + requests + data transfer out.
- It's **object** storage, not a file system or a disk – you can't "mount" it like EBS and edit part of a file; you upload/replace whole objects.

## Buckets

A **bucket** is a top-level container for objects.

- Bucket names are **globally unique** across all AWS accounts (that's why mine is `vansh-24bcs10268-terraform-s3-demo`).
- 3–63 characters, lowercase letters, numbers, hyphens and dots.
- Created in a specific **region**, but the namespace is global.
- New buckets are **private by default** and have "Block Public Access" turned ON.

```bash
aws s3 mb s3://vansh-24bcs10268-notes --region ap-south-1
aws s3 ls
```

## Objects

An **object** is a file stored in a bucket. Each object has:

| Part | Meaning |
| :--- | :--- |
| **Key** | the full name/path, e.g. `images/2026/logo.png` |
| **Value** | the actual data (bytes) |
| **Metadata** | content-type, last-modified, custom tags |
| **Version ID** | if versioning is enabled |

S3 has a **flat structure** – "folders" are just a prefix in the key (`images/2026/`), the console only shows them as folders.

```bash
aws s3 cp notes.txt s3://vansh-24bcs10268-notes/docs/notes.txt
aws s3 ls s3://vansh-24bcs10268-notes/docs/
aws s3 sync ./site s3://vansh-24bcs10268-notes/site
```

## Storage classes

You choose a storage class per object depending on how often you access it. Cheaper storage = higher retrieval cost / slower access.

| Class | Access pattern | Notes |
| :--- | :--- | :--- |
| **S3 Standard** | frequent | default, low latency, highest storage price |
| **S3 Intelligent-Tiering** | unknown / changing | automatically moves objects between tiers |
| **S3 Standard-IA** | infrequent (≈ monthly) | cheaper storage, retrieval fee, min 30 days |
| **S3 One Zone-IA** | infrequent, re-creatable data | stored in only 1 AZ, even cheaper |
| **S3 Glacier Instant Retrieval** | rare (≈ quarterly) but need ms access | archive with instant reads |
| **S3 Glacier Flexible Retrieval** | archive | retrieval in minutes to hours |
| **S3 Glacier Deep Archive** | long-term (7–10 years, compliance) | cheapest, retrieval up to 12–48 hours |
| **S3 Express One Zone** | very high performance | single-digit ms latency, single AZ |

## Versioning

When **versioning** is enabled, S3 keeps **every version** of an object instead of overwriting it.

- Uploading the same key again creates a **new version**; old one is still there.
- Deleting an object just adds a **delete marker** – you can remove the marker to "undelete".
- Protects against accidental overwrite/delete and ransomware.
- Once enabled it can only be **suspended**, not fully turned off.
- Old versions still cost storage → combine with lifecycle rules.

```bash
aws s3api put-bucket-versioning --bucket vansh-24bcs10268-notes --versioning-configuration Status=Enabled
aws s3api list-object-versions --bucket vansh-24bcs10268-notes
```

In my Terraform demo this is the `aws_s3_bucket_versioning` resource.

## Lifecycle policies

**Lifecycle rules** automatically move or delete objects after some time, which saves money.

- **Transition actions** – e.g. move to Standard-IA after 30 days, Glacier after 90 days.
- **Expiration actions** – delete after 365 days, delete old (non-current) versions after 30 days, clean up incomplete multipart uploads.

Example rule (JSON):

```json
{
  "Rules": [
    {
      "ID": "logs-archive",
      "Filter": { "Prefix": "logs/" },
      "Status": "Enabled",
      "Transitions": [
        { "Days": 30, "StorageClass": "STANDARD_IA" },
        { "Days": 90, "StorageClass": "GLACIER" }
      ],
      "Expiration": { "Days": 365 },
      "NoncurrentVersionExpiration": { "NoncurrentDays": 30 }
    }
  ]
}
```

```bash
aws s3api put-bucket-lifecycle-configuration --bucket vansh-24bcs10268-notes --lifecycle-configuration file://lifecycle.json
```

## Encryption

**At rest** (on AWS disks):

| Option | Who manages the key |
| :--- | :--- |
| **SSE-S3** (AES-256) | S3 itself – **default for all new objects since 2023** |
| **SSE-KMS** | AWS KMS key – you get key policies + CloudTrail audit of key usage |
| **DSSE-KMS** | two layers of KMS encryption (compliance) |
| **SSE-C** | you provide the key with every request |
| **Client-side** | you encrypt before uploading |

**In transit**: use HTTPS. You can force it with a bucket policy that denies requests where `aws:SecureTransport` is `false`.

In my Terraform demo I set `sse_algorithm = "AES256"` (SSE-S3).

## Bucket policies

A **bucket policy** is a **resource-based** JSON policy attached to the bucket. It controls who can access the bucket and its objects – including other AWS accounts or the public.

Example 1 – deny any non-HTTPS request:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::vansh-24bcs10268-notes",
        "arn:aws:s3:::vansh-24bcs10268-notes/*"
      ],
      "Condition": { "Bool": { "aws:SecureTransport": "false" } }
    }
  ]
}
```

Example 2 – public read for a static website (Block Public Access must be turned off first):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::vansh-24bcs10268-site/*"
    }
  ]
}
```

Other access controls: **IAM policies** (on users/roles), **Block Public Access** (safety switch), **ACLs** (old, disabled by default now), and **pre-signed URLs** (temporary link to a private object).

```bash
aws s3 presign s3://vansh-24bcs10268-notes/docs/notes.txt --expires-in 3600
```

## Common use cases

- **Backups and disaster recovery** (DB dumps, EBS snapshots are stored in S3).
- **Static website hosting** (HTML/CSS/JS), often with CloudFront in front.
- **Media storage** – user uploads, images, videos.
- **Data lake** for analytics (Athena, Redshift Spectrum, EMR query data directly in S3).
- **Log storage** (CloudTrail, ALB logs, app logs).
- **Terraform remote state** (S3 backend + DynamoDB/S3 lock).
- **CI/CD artifacts** – build outputs, release packages.
- **Archiving** for compliance using Glacier.
