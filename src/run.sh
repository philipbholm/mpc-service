#!/bin/bash

nitro-cli run-enclave \
    --cpu-count 1 \
    --memory 4000 \
    --eif-path out.eif \
    --enclave-cid 4 \
    --debug-mode
nitro-cli console --enclave-id $(nitro-cli describe-enclaves | jq -r ".[0].EnclaveID") 