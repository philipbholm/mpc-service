#!/bin/bash

# docker build -t enclave_base src/enclave/base_image
docker build -t server src/enclave

docker build -t builder - <<EOF
FROM amazonlinux:2023

RUN dnf install -y jq aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel

CMD ["/bin/bash", "-c", "nitro-cli build-enclave --docker-uri server --output-file dummy.eif | jq --raw-output '.Measurements.PCR0'"]
EOF

PCR0=$(docker run -v /var/run/docker.sock:/var/run/docker.sock -it builder)

echo $PCR0
