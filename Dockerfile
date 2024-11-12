FROM amazonlinux:2023

RUN dnf install -y jq aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel

CMD ["/bin/bash", "-c", "nitro-cli build-enclave --docker-uri server --output-file dummy.eif | jq --raw-output '.Measurements.PCR0'"]