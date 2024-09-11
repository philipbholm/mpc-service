#!/bin/bash
docker build -t server src/enclave
nitro-cli build-enclave --docker-uri server --output-file server.eif
nitro-cli run-enclave --eif-path server.eif --cpu-count 1 --memory 2048 --debug-mode
nitro-cli console --enclave-id $(nitro-cli describe-enclaves | jq -r '.[0].EnclaveID')