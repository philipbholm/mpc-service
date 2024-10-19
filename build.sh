#!/bin/bash

set -e

# INFO: 
# https://medium.com/nttlabs/bit-for-bit-reproducible-builds-with-dockerfile-7cc2b9faed9f
# https://reproducible-builds.org/

# TODO:
# - Make build reproducible on mac without python dependencies 
# - Add dependecies from pip
# - Ensure consistent results with remote instance

echo "Preparing builder for enclave image."

# Run buildkit with a specific version inside docker
docker run -d --name buildkitd --privileged moby/buildkit:v0.16.0
export BUILDKIT_HOST=docker-container://buildkitd
# Or set the current builder to use a specific version
docker buildx create \
    --driver=docker-container \
    --driver-opt image=moby/buildkit:v0.16.0 \
    --use

# Build enclave image locally and add image sha to config.tfvars
# RUN find /app -exec touch -t 202401010000.00 {} +
# TODO: Is --no-cache needed?
docker build -t local2 -f debian.Dockerfile --build-arg SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct) .
diffoci diff 


docker build -t local2 \
    -f debian.Dockerfile \
    --platform linux/arm64 \
    --build-arg SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct) \
    .

    --no-cache \
    --output type=image,rewrite-timestamp=true \
docker build -t builder - <<EOF
FROM amazonlinux:2023

RUN dnf install -y jq aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel

CMD ["/bin/bash", "-c", "nitro-cli build-enclave --docker-uri server --output-file dummy.eif | jq --raw-output '.Measurements.PCR0'"]
EOF

# TODO: Set hash on base image if necessary
# TODO: Set versions of nitro-cli

echo "Building enclave image file." 
enclave_image_sha=$(docker run --rm -v /var/run/docker.sock:/var/run/docker.sock builder)
