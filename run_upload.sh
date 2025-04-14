#!/bin/bash
set -e

# Load non-sensitive values directly
export S3_BUCKET_NAME=$(terraform output -raw bucket_name)
export AWS_KMS_KEY_ARN=$(terraform output -raw kms_key_arn)
export ADMIN_USER_ARN=$(terraform output -raw admin_user_arn)
# export EDITOR_USER_ARN=$(terraform output -raw editor_user_arn)

# For sensitive credentials, use JSON output
TF_ADMIN_CREDS=$(terraform output -json admin_credentials)
# TF_EDITOR_CREDS=$(terraform output -json editor_credentials)

# Set role-specific credentials
# if [ "${USER_ROLE}" = "editor" ]; then
#     export ACCESS_KEY=$(echo "$TF_EDITOR_CREDS" | jq -r .access_key)
#     export SECRET_KEY=$(echo "$TF_EDITOR_CREDS" | jq -r .secret_key)
# else
    # Default to admin role
    export USER_ROLE=admin
    export ACCESS_KEY=$(echo "$TF_ADMIN_CREDS" | jq -r .access_key)
    export SECRET_KEY=$(echo "$TF_ADMIN_CREDS" | jq -r .secret_key)
# fi

# Debug print (mask sensitive values)
echo "Using bucket: $S3_BUCKET_NAME"
echo "Uploading with KMS key: $AWS_KMS_KEY_ARN"
echo "User role: ${USER_ROLE}"
echo "Using access key: ${ACCESS_KEY:0:4}...${ACCESS_KEY: -4}"

# Pass through to Python script
python3 ./script/uploader.py "$@"

# run_upload.sh editor LESSONS.zip