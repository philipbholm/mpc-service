#!/bin/bash

set -e

TARGET_ARCH=arm64

# TODO:
# Add support for amd64 builds 
# Cleanup
# Change source date epoch

echo "Preparing builder for enclave image."

# Or set the current builder to use a specific version
docker buildx create \
    --driver=docker-container \
    --driver-opt image=moby/buildkit:v0.17.0 \
    --name repro

docker buildx --builder repro \
    build \
    -t server \
    --platform linux/$TARGET_ARCH \
    --no-cache \
    --build-arg SOURCE_DATE_EPOCH=0 \
    --output type=docker,dest=server.tar,rewrite-timestamp=true \
    src/enclave

# Enable QEMU if necessary
# https://github.com/multiarch/qemu-user-static
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Build enclave image locally
docker build -t builder --platform linux/$TARGET_ARCH - <<EOF
FROM amazonlinux:2023

RUN dnf install -y jq aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel

CMD ["/bin/bash", "-c", "nitro-cli build-enclave --docker-uri server --output-file dummy.eif | jq --raw-output '.Measurements.PCR0'"]
EOF

echo "Building enclave image file." 
enclave_image_sha=$(docker run --rm -v /var/run/docker.sock:/var/run/docker.sock builder)


# tmp commands
docker buildx create --driver=docker-container --driver-opt image=moby/buildkit:v0.17.0 --name repro

docker buildx --builder repro build -t server --platform linux/arm64 --no-cache --build-arg SOURCE_DATE_EPOCH=0 --output type=docker,dest=server.tar,rewrite-timestamp=true src/enclave

docker build -t builder --platform linux/arm64 .

docker run --rm --platform linux/arm64 -v /var/run/docker.sock:/var/run/docker.sock builder

# Compare differences
docker save -o remote.tar remote
scp -i ~/.ssh/mpc-key.pem ec2-user@$(tofu -chdir=infra output -raw public_ip):/home/ec2-user/mpc-service/remote.tar ./
docker load -i remote.tar
diffoci diff --semantic docker://local docker://remote

# Ubuntu ARM
ssh -i "sandbox.pem" ubuntu@18.185.248.204
scp -i ~/.ssh/sandbox.pem ubuntu@18.185.248.204:/home/ubuntu/mpc-service/oci-ubu.tar ./
scp -i ~/.ssh/sandbox.pem ubuntu@18.185.248.204:/home/ubuntu/mpc-service/tar-ubu.tar ./