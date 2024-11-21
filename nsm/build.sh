#!/bin/bash

set -e 

error_handler() {
    echo "Error occurred in script at line $1"
    exit 1
}
trap 'error_handler $LINENO' ERR

docker build -t nsm . > /dev/null 2>&1
nitro-cli build-enclave --docker-uri nsm --output-file out.eif > /dev/null 2>&1
nitro-cli run-enclave \
    --cpu-count 1 \
    --memory 8000 \
    --eif-path out.eif \
    --enclave-cid 4 \
    --debug-mode > /dev/null 2>&1
nitro-cli console --enclave-id $(nitro-cli describe-enclaves | jq -r ".[0].EnclaveID") 