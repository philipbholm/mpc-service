#!/bin/bash

# Get credentials
aws_role_arn=$(terraform output --raw data_owner_role_arn)
credentials=$(aws sts assume-role --role-arn $aws_role_arn --role-session-name encrypt-session)

# Export temporary credentials to a file
echo "AWS_ACCESS_KEY_ID=$(echo $credentials | jq -r '.Credentials.AccessKeyId')" > .env
echo "AWS_SECRET_ACCESS_KEY=$(echo $credentials | jq -r '.Credentials.SecretAccessKey')" >> .env
echo "AWS_SESSION_TOKEN=$(echo $credentials | jq -r '.Credentials.SessionToken')" >> .env
echo "S3_BUCKET_ARN=$(terraform output --raw s3_bucket_arn)" >> .env
echo "KMS_KEY_ARN=$(terraform output --raw kms_key_arn)" >> .env
echo "KMS_KEY_ID=$(terraform output --raw kms_key_id)" >> .env
