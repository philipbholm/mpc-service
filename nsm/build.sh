#!/bin/bash

set -e 

docker build -t nsm .
nitro-cli build-enclave --docker-uri nsm --output-file nsm.eif
nitro-cli run-enclave \
    --cpu-count 1 \
    --memory 8000 \
    --eif-path nsm.eif \
    --enclave-cid 4 \
    --debug-mode
nitro-cli console --enclave-id $(nitro-cli describe-enclaves | jq -r ".[0].EnclaveID") 