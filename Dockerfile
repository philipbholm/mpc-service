FROM amazonlinux:2023

RUN dnf install -y jq aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel

WORKDIR /build