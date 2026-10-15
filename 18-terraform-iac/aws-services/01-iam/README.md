# Session 18 – AWS IAM (Governance)

**Name:** Vansh Malhotra  
**Roll No:** 24bcs10268

## What is IAM?

**IAM (Identity and Access Management)** is the AWS service that decides **who** can access your AWS account and **what** they are allowed to do. It answers two questions for every API call:

1. **Authentication** – who are you? (username + password, access keys, or a temporary role session)
2. **Authorization** – are you allowed to do this action on this resource?

IAM is a **global** service (not tied to a region) and it is **free** – you don't pay for users, groups or policies.

By default every new identity has **no permissions at all** (implicit deny). You have to grant access explicitly.

## Root user

When you create an AWS account you get the **root user** (the email you signed up with). It has unlimited power, including closing the account and changing billing. You should only use it for a few account-level tasks, turn on MFA for it, and never create access keys for it.

## Users

An **IAM user** is a permanent identity for one person or one application.

- Can have a **console password** (to log in to the web console) and/or **access keys** (Access Key ID + Secret Access Key, for CLI/SDK/Terraform).
- Has long-term credentials, so they must be protected and rotated.

```bash
aws iam create-user --user-name vansh-dev
aws iam create-access-key --user-name vansh-dev
```

## Groups

A **group** is a collection of users. You attach policies to the group, and every user in it gets those permissions. This is much easier than attaching policies to every user one by one.

Example: `Developers`, `Admins`, `ReadOnly`.

- A user can be in multiple groups.
- Groups cannot be nested (no group inside a group).
- A group is not an identity – you can't log in "as a group".

```bash
aws iam create-group --group-name Developers
aws iam add-user-to-group --group-name Developers --user-name vansh-dev
```

## Roles

A **role** is an identity with permissions but **no permanent credentials**. Someone (or something) *assumes* the role and gets **temporary credentials** from AWS STS that expire automatically.

Who assumes roles:

- **AWS services** – e.g. an EC2 instance role so the app on EC2 can read from S3 without storing keys.
- **Other AWS accounts** – cross-account access.
- **Federated users** – people logging in via Google/Okta/AD (SSO).
- **CI/CD** – GitHub Actions using OIDC to assume a role instead of storing keys as secrets.

A role has two policies:

- **Trust policy** – *who* can assume the role.
- **Permission policy** – *what* the role can do.

Trust policy example (lets EC2 assume the role):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

## Policies

A **policy** is a JSON document that lists permissions. Each statement has:

| Field | Meaning |
| :--- | :--- |
| `Effect` | `Allow` or `Deny` |
| `Action` | API actions, e.g. `s3:GetObject`, `ec2:StartInstances` |
| `Resource` | ARN(s) the action applies to |
| `Condition` (optional) | extra rules, e.g. only from a certain IP, only with MFA |

Example – read-only access to one bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::vansh-24bcs10268-terraform-s3-demo"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::vansh-24bcs10268-terraform-s3-demo/*"
    }
  ]
}
```

### Types of policies

- **AWS managed** – written by AWS, e.g. `AmazonS3ReadOnlyAccess`, `AdministratorAccess`.
- **Customer managed** – written by you, reusable, versioned.
- **Inline** – embedded directly in one user/group/role (deleted with it).
- **Resource-based** – attached to a resource instead of an identity, e.g. an S3 bucket policy.
- **Permission boundaries / SCPs** – set the *maximum* permissions (used in AWS Organizations).

## Permissions – how AWS evaluates them

1. Everything starts as **implicit deny**.
2. If any policy has an **explicit `Deny`** for the action → denied. Explicit deny always wins.
3. Else if some policy has an **`Allow`** → allowed.
4. Else → denied.

```text
Explicit Deny  >  Allow  >  Implicit Deny (default)
```

## Least privilege

The **principle of least privilege** means giving each user/role **only the permissions they actually need, nothing more**.

Bad: giving a CI pipeline `AdministratorAccess` because it's easy.  
Good: giving it only `s3:PutObject` on the one bucket it uploads artifacts to.

How to practise it:

- Start with zero permissions and add as needed.
- Scope `Resource` to specific ARNs instead of `"*"`.
- Use **IAM Access Analyzer** and "last accessed" info to remove unused permissions.

## IAM best practices

- Lock away the root user, enable **MFA** on it, and don't create root access keys.
- Enable **MFA** for all human users.
- Prefer **roles and temporary credentials** over long-term access keys (EC2 instance roles, GitHub OIDC, IAM Identity Center/SSO).
- Manage permissions with **groups**, not individual users.
- Follow **least privilege**; review permissions regularly.
- **Rotate** access keys and remove unused users/keys.
- Use a strong **password policy**.
- Never put access keys in code or Git (use `aws configure` or environment variables, and secret scanners like Gitleaks).
- Turn on **CloudTrail** so every API call is logged and auditable.

## Common use cases

- Giving each team member their own login with the right permissions (devs vs admins vs read-only).
- Letting an **EC2 instance or Lambda** access S3/DynamoDB using a role (no hard-coded keys).
- **CI/CD pipelines** deploying to AWS (Terraform, GitHub Actions with OIDC).
- **Cross-account access** – e.g. a central security account that can read logs from all others.
- **SSO / federation** – employees log in with company credentials.

## Quick summary

| Concept | One-line meaning |
| :--- | :--- |
| User | Permanent identity for a person/app |
| Group | Bunch of users sharing policies |
| Role | Identity with temporary credentials, assumed by someone/something |
| Policy | JSON listing allowed/denied actions on resources |
| Least privilege | Only the minimum permissions needed |
