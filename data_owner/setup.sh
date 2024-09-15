#!/bin/bash

set -e

echo "Preparing builder for enclave image."
# Build enclave image locally and add image sha to config.tfvars
# TODO: Make builds reproducible (no-cache and sha hashes for base images and python packages)
docker build -t server --platform linux/arm64 ../src/enclave
docker build -t builder - <<EOF
FROM amazonlinux:2023

RUN dnf install -y jq aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel

CMD ["/bin/bash", "-c", "nitro-cli build-enclave --docker-uri server --output-file dummy.eif | jq --raw-output '.Measurements.PCR0'"]
EOF

echo "Building enclave image file." 
enclave_image_sha=$(docker run --rm -v /var/run/docker.sock:/var/run/docker.sock builder)

echo "Updating the image hash in config.tfvars with $enclave_image_sha"
sed -i.bak "s/^enclave_image_sha = .*/enclave_image_sha = \"$enclave_image_sha\"/" config.tfvars && rm config.tfvars.bak


# Run terraform files
docker build -t terraform -f - . <<EOF
FROM hashicorp/terraform:1.9.5

WORKDIR /infra 

ENTRYPOINT ["terraform"]
EOF

# Remove or fix this so it does not use alpine
docker run --rm -v $(pwd):/local -v terraform-vol:/infra alpine sh -c "cp /local/main.tf /local/config.tfvars /infra/"

echo "Initializing terraform."
docker run --rm -v terraform-vol:/infra terraform init

# TODO: Find better way of handling credentials
# TODO: Use IAM role temp credentials or not?
echo "Running terraform plan."
docker run --rm \
    -v terraform-vol:/infra \
    -v ~/.aws:/root/.aws \
    terraform plan

echo "Running terraform apply."
docker run --rm \
    -v terraform-vol:/infra \
    -v ~/.aws:/root/.aws \
    terraform apply -auto-approve

# Store terraform output to env file
rm -f .env
echo "DATA_OWNER_ROLE_ARN=$(docker run --rm -v terraform-vol:/infra terraform output --raw data_owner_role_arn)" > .env
echo "S3_BUCKET_ARN=$(docker run --rm -v terraform-vol:/infra terraform output --raw s3_bucket_arn)" >> .env
echo "KMS_KEY_ARN=$(docker run --rm -v terraform-vol:/infra terraform output --raw kms_key_arn)" >> .env


# Encrypt and upload data
docker build -t encrypt -f - . <<EOF
FROM amazonlinux:2023

RUN dnf install -y jq unzip python3-pip && \
    pip3 install aws-encryption-sdk-cli && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install 

WORKDIR /data

ENTRYPOINT ["/bin/bash", "-c"]

CMD ["aws-encryption-cli --encrypt \
    --input 'data.csv' \
    --output 'data.enc' \
    --wrapping-keys key=$KMS_KEY_ARN \
    --encryption-context purpose=test \
    --suppress-metadata && \
    aws s3 cp data.enc s3://$(echo $S3_BUCKET_ARN | cut -d ':' -f 6)/data.enc && \
    rm data.enc"]
EOF

echo "Encrypting and uploading data."
docker run --rm -v $(pwd)/data:/data -v ~/.aws:/root/.aws --env-file .env encrypt
