#!/bin/bash

docker build -t enclave_base --no-cache src/enclave/base_image
docker build -t server --no-cache src/enclave
docker build -t builder --no-cache .
docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/build:/build -it builder
