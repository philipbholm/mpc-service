#!/bin/bash

docker build -t enclave_base src/enclave/base_image
docker build -t server src/enclave
docker build -t builder .
docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/build:/build -it builder
