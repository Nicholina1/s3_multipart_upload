# Secure Upload System

A fully automated and secure AWS-based file upload system using Terraform and Python. This system provisions an S3 bucket with server-side encryption (KMS), creates IAM roles and policies for fine-grained access control, sets up CloudWatch monitoring for suspicious activity, and provides a Python-based uploader that supports KMS encryption and presigned URLs.

---

## Features

- **Terraform Infrastructure as Code (IaC):**
  - S3 bucket with access logging, transfer acceleration, versioning, lifecycle rules.
  - Custom KMS key with fine-tuned IAM permissions.
  - IAM roles and policies for `admin` and `editor`.
  - CloudWatch alarms for:
    - Unauthorized access attempts
    - Suspicious operations (e.g., DeleteBucket, PutBucketPolicy)
  - SNS topic to alert on alarms.

- **Python Multipart Uploader:**
  - Authenticates using IAM user credentials.
  - Uploads large files with multipart upload and KMS encryption.
  - Generates a time-limited presigned URL for file access.
  - Debugs AWS credentials and session configuration.

---

## Project Structure

```
secure-upload-system/
├── deploy.sh                   # Deployment script
├── main.tf                     # Main Terraform configuration
├── outputs.tf                  # Output definitions
├── variables.tf                # Variable definitions
├── run_upload.sh               # File upload script
├── script/
│   └── uploader.py             # Python upload implementation
└── modules/
    ├── iam_policy/             # IAM policy configuration
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── iam_role/               # IAM role configuration
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── kms/                    # KMS key configuration
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    ├── monitoring/             # CloudWatch configuration
    │   ├── main.tf
    │   ├── outputs.tf
    │   └── variables.tf
    └── s3/                     # S3 bucket configuration
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

---

## Getting Started

### Prerequisites

- Terraform CLI (v1.3+)
- AWS CLI (configured)
- Python 3.7+
- `boto3` and `botocore`
- `jq` (used in shell scripts)

---

### 1. Deploy Infrastructure

```bash
chmod +x deploy.sh
./deploy.sh
```

> This will create the full infrastructure stack, and optionally prompt you before applying changes.

---

### 2. Upload Files Securely

```bash
chmod +x run_upload.sh
./run_upload.sh path/to/your/file.zip
```

> This script sets the necessary environment variables, retrieves credentials, and calls the Python uploader.

---

### Environment Variables

Set automatically by `run_upload.sh`:

- `S3_BUCKET_NAME`
- `AWS_KMS_KEY_ARN`
- `ACCESS_KEY`
- `SECRET_KEY`
- `USER_ROLE` (defaults to `admin`)
- `URL_EXPIRY_HOURS` (optional, default: `24`)

---

## IAM Access Levels

- **Admin**
  - Full access to S3 bucket and KMS key.
- **Editor**
  - Limited to uploading, downloading, and managing objects.
- **Viewer (optional)** *(commented out in Terraform but easy to enable)*

---

## Monitoring

CloudWatch Alarms track:
- Unauthorized access attempts (`AccessDenied`, `UnauthorizedOperation`)
- Suspicious operations (`DeleteBucket`, `PutBucketPolicy`, `PutBucketAcl`)

Alerts are sent to an SNS topic.

---

## Customization Tips

- Enable viewer access by uncommenting the `viewer` block in `iam_policy/main.tf`.
- Customize `expiration_days`, `log_retention_days`, or `alarm thresholds` in `variables.tf`.
- Adjust trusted services or principals in the IAM role module.

---

## Testing

To test access levels:
- Switch `USER_ROLE` in `run_upload.sh` and observe behavior.
- Try uploading files and accessing via presigned URLs.
- Trigger alarms via unauthorized access attempts (optional for testing).

---

## Output Examples

After deployment:

```bash
terraform output
```

Returns:
- `bucket_name`
- `kms_key_arn`
- `admin_user_arn`
- `editor_user_arn`
- `sns_topic_arn`
- `security_alarms`
- Sensitive credentials (access_key & secret)

---

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

---

## Author Notes

This system is ideal for secure file intake pipelines, regulatory-compliant uploads (e.g., HIPAA), or large file ingestion services that need encryption, logging and access control.

---

