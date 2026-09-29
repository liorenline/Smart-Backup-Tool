# Smart Backup Tool

A lightweight tool for backing up config files, notes and small projects to Amazon S3.
This repository currently contains the **AWS infrastructure** for the tool, managed with Terraform. The Python backup script is coming next.

## What gets created

| Resource | Purpose |
|---|---|
| S3 bucket | Stores backup archives |
| Public access block | Makes sure the bucket can never become public |
| Server-side encryption (SSE-S3) | Encrypts every object at rest, free of charge |
| Versioning | Keeps previous versions if an object is overwritten or deleted |
| Lifecycle rule | Deletes backups older than `retention_days`, cleans up old versions after 7 days and aborts incomplete multipart uploads after 1 day |
| IAM user `smart-backup-uploader` | Dedicated identity for the backup script |
| Inline IAM policy | Allows **only** `s3:PutObject` into `<bucket>/<backup_prefix>/*` |

### Security model

The backup script runs under a separate IAM user with the least privilege possible. It can upload new backups into its own prefix, and nothing else:

- ✅ upload to `s3://<bucket>/<backup_prefix>/`
- ❌ upload anywhere else in the bucket
- ❌ list bucket contents
- ❌ download or delete backups

If the script's access key is ever leaked, the attacker can't read, delete or list your backups, and has no access to the rest of the AWS account. Restores are done manually with an admin profile.
## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.5 or newer
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- An AWS account and an IAM user with admin permissions for running Terraform (don't use root access keys)

## Setup

### 1. Configure an admin AWS profile

Create an access key for your admin IAM user in the AWS Console, then:

```bash
aws configure --profile <your-admin-profile>
aws sts get-caller-identity --profile <your-admin-profile>
```

### 2. Set your values

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`. At minimum, set a **globally unique** `bucket_name` (lowercase letters, numbers and hyphens only) and your `aws_profile`.

`terraform.tfvars` is git-ignored, so your values stay local.

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

The plan should show `8 to add` on the first run.

### 4. Create credentials for the backup script

Terraform creates the uploader user but deliberately **not** its access key, so the secret never ends up in the Terraform state.

1. In the AWS Console, open **IAM → Users → smart-backup-uploader → Security credentials**.
2. Click **Create access key** and choose **Command Line Interface (CLI)**.
3. Save the key into a separate profile:

```bash
aws configure --profile smart-backup
```

## Verify permissions

```bash
echo test > test.txt

# Should succeed
aws s3 cp test.txt s3://<bucket_name>/<backup_prefix>/test.txt --profile smart-backup

# All three should fail with AccessDenied / Forbidden
aws s3 cp test.txt s3://<bucket_name>/other/test.txt --profile smart-backup
aws s3 ls s3://<bucket_name> --profile smart-backup
aws s3 cp s3://<bucket_name>/<backup_prefix>/test.txt downloaded.txt --profile smart-backup

rm test.txt
```

## Variables

| Name | Description | Type | Default |
|---|---|---|---|
| `bucket_name` | Globally unique S3 bucket name | `string` | — (required) |
| `aws_profile` | AWS CLI profile for Terraform. `null` uses the default credential chain | `string` | `null` |
| `aws_region` | AWS region for all resources | `string` | `eu-central-1` |
| `backup_prefix` | Key prefix for backup objects | `string` | `laptop` |
| `retention_days` | Days to keep backups before automatic deletion (must be > 0) | `number` | `30` |
| `iam_user_name` | Name of the IAM user for the backup script | `string` | `smart-backup-uploader` |

## Terraform state

State is stored **locally** in `terraform/terraform.tfstate` and is git-ignored.

- Don't delete it: without it Terraform loses track of the resources it created.
- Back it up somewhere safe if you rely on this setup long-term.

## Costs

For a personal backup workload this is close to free: S3 Standard storage costs a few cents per GB per month, SSE-S3 encryption and IAM are free. The lifecycle rule keeps storage from growing forever.

## Tearing down

`terraform destroy` will intentionally fail while the bucket contains objects (`force_destroy = false`), so a single command can't wipe your backups.

To remove everything:

1. Delete the uploader's access key in the IAM Console (otherwise IAM refuses to delete the user).
2. Empty the bucket in the S3 Console, including all object versions.
3. Run `terraform destroy`.
