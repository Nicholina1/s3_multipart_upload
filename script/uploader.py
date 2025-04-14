#!/usr/bin/env python3
import boto3
import os
import sys
import math
from botocore.exceptions import ClientError
from botocore.config import Config
from datetime import datetime, timedelta

def debug_print_credentials(session):
    """Show current AWS credentials being used"""
    credentials = session.get_credentials()

    print("\n=== AWS Credentials Debug ===")
    print(f"Using profile: {session.profile_name or 'default'}")
    if credentials:
        masked_key = credentials.access_key[:4] + '...' + credentials.access_key[-4:]
        print(f"Access key: {masked_key}")
        print(f"Region: {session.region_name}")
        print("Transfer Acceleration: Enabled")
    else:
        print("No credentials found!")
    print("===========================\n")

def validate_config():
    """Validate all required environment variables"""
    required_vars = {
        'S3_BUCKET_NAME': os.getenv('S3_BUCKET_NAME'),
        'AWS_KMS_KEY_ARN': os.getenv('AWS_KMS_KEY_ARN'),
        'ACCESS_KEY': os.getenv('ACCESS_KEY'),
        'SECRET_KEY': os.getenv('SECRET_KEY'),
        'USER_ROLE': os.getenv('USER_ROLE', 'admin').lower(),
        'URL_EXPIRY_HOURS': os.getenv('URL_EXPIRY_HOURS', '24')
    }

    missing = [k for k, v in required_vars.items() if not v and k != 'URL_EXPIRY_HOURS']
    if missing:
        print(f"Error: Missing environment variables: {', '.join(missing)}")
        sys.exit(1)

    if required_vars['USER_ROLE'] not in ['admin', 'editor']:
        print("Error: Invalid USER_ROLE. Must be 'admin' or 'editor'")
        sys.exit(1)

    try:
        url_expiry = int(required_vars['URL_EXPIRY_HOURS'])
    except ValueError:
        print("Error: URL_EXPIRY_HOURS must be a valid integer")
        sys.exit(1)

    return {
        'bucket': required_vars['S3_BUCKET_NAME'],
        'kms_key': required_vars['AWS_KMS_KEY_ARN'],
        'access_key': required_vars['ACCESS_KEY'],
        'secret_key': required_vars['SECRET_KEY'],
        'user_role': required_vars['USER_ROLE'],
        'url_expiry_hours': url_expiry
    }

def create_s3_client(config):
    """Create authenticated S3 client with transfer acceleration and SigV4"""
    try:
        s3_config = Config(
            s3={'use_accelerate_endpoint': True},
            signature_version='s3v4'
        )

        session = boto3.Session(
            aws_access_key_id=config['access_key'],
            aws_secret_access_key=config['secret_key'],
            region_name=os.getenv('AWS_REGION', 'us-east-1')
        )

        sts = session.client('sts')
        identity = sts.get_caller_identity()
        print(f"Authenticated as {identity['Arn']} ({config['user_role']})")

        debug_print_credentials(session)
        return session.client('s3', config=s3_config)
    except ClientError as e:
        print(f"Authentication failed: {e.response['Error']['Message']}")
        sys.exit(1)

def generate_presigned_url(s3_client, bucket_name, object_key, expiry_hours):
    """Generate a presigned URL for the uploaded object"""
    try:
        url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket_name, 'Key': object_key},
            ExpiresIn=expiry_hours * 3600
        )
        expiry_time = (datetime.now() + timedelta(hours=expiry_hours)).strftime('%Y-%m-%d %H:%M:%S')
        print(f"\nPresigned URL (expires at {expiry_time}):")
        print(url)
        return url
    except ClientError as e:
        print(f"Failed to generate presigned URL: {e.response['Error']['Message']}")
        return None

def multipart_upload(s3_client, file_path, bucket_name, kms_key_arn, url_expiry_hours):
    """Handle multipart upload with KMS encryption and return presigned URL"""
    file_name = os.path.basename(file_path)

    try:
        response = s3_client.create_multipart_upload(
            Bucket=bucket_name,
            Key=file_name,
            ServerSideEncryption='aws:kms',
            SSEKMSKeyId=kms_key_arn
        )
        upload_id = response['UploadId']
        print(f"Initiated upload (ID: {upload_id})")

        part_size = 8 * 1024 * 1024
        file_size = os.path.getsize(file_path)
        part_count = math.ceil(file_size / part_size)
        parts = []

        with open(file_path, 'rb') as f:
            for i in range(1, part_count + 1):
                print(f"Uploading part {i}/{part_count}...")
                offset = part_size * (i - 1)
                bytes_to_read = min(part_size, file_size - offset)
                f.seek(offset)
                data = f.read(bytes_to_read)

                response = s3_client.upload_part(
                    Bucket=bucket_name,
                    Key=file_name,
                    PartNumber=i,
                    UploadId=upload_id,
                    Body=data
                )
                parts.append({'PartNumber': i, 'ETag': response['ETag']})

        s3_client.complete_multipart_upload(
            Bucket=bucket_name,
            Key=file_name,
            UploadId=upload_id,
            MultipartUpload={'Parts': parts}
        )
        print(f"Upload completed successfully! s3://{bucket_name}/{file_name}")

        return generate_presigned_url(s3_client, bucket_name, file_name, url_expiry_hours)

    except Exception as e:
        print(f"Upload failed: {str(e)}")
        if 'upload_id' in locals():
            s3_client.abort_multipart_upload(
                Bucket=bucket_name,
                Key=file_name,
                UploadId=upload_id
            )
            print("Aborted incomplete upload")
        sys.exit(1)

def main():
    print("=== AWS S3 Secure Upload Setup ===")
    config = validate_config()
    s3_client = create_s3_client(config)

    try:
        s3_client.head_bucket(Bucket=config['bucket'])
        print(f"Verified access to bucket: {config['bucket']}")
    except ClientError as e:
        print(f"Bucket access failed: {e.response['Error']['Message']}")
        sys.exit(1)

    if len(sys.argv) < 2:
        print("Usage: ./run_upload.sh <file_path>")
        sys.exit(1)

    file_path = sys.argv[1]
    if not os.path.exists(file_path):
        print(f"Error: File not found: {file_path}")
        sys.exit(1)

    presigned_url = multipart_upload(
        s3_client=s3_client,
        file_path=file_path,
        bucket_name=config['bucket'],
        kms_key_arn=config['kms_key'],
        url_expiry_hours=config['url_expiry_hours']
    )

    if presigned_url:
        return presigned_url

if __name__ == "__main__":
    main()

