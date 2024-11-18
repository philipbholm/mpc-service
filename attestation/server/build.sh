#!/bin/bash

set -e 

docker build -t image .
nitro-cli build-enclave --docker-uri image --output-file image.eif
nitro-cli run-enclave \
    --cpu-count 1 \
    --memory 2048 \
    --eif-path image.eif \
    --enclave-cid 4 \
    --debug-mode
nitro-cli console --enclave-id $(nitro-cli describe-enclaves | jq -r ".[0].EnclaveID") 