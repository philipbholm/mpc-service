#!/bin/bash

set -e 

docker build -t nsm -f example/attestation/Dockerfile .
nitro-cli build-enclave --docker-uri nsm --output-file out.eif 
nitro-cli run-enclave \
    --cpu-count 1 \
    --memory 2000 \
    --eif-path out.eif \
    --enclave-cid 4 \
    --debug-mode
nitro-cli console --enclave-id $(nitro-cli describe-enclaves | jq -r ".[0].EnclaveID") 