#!/bin/bash

docker build -t enclave_base src/enclave/base_image
docker build -t server src/enclave

docker build -t builder - <<EOF
FROM amazonlinux:2

RUN amazon-linux-extras install aws-nitro-enclaves-cli
RUN yum install -y aws-nitro-enclaves-cli-devel

WORKDIR /build

CMD ["/bin/bash", "-c", "nitro-cli build-enclave --docker-uri server --output-file server.eif"]
EOF

docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/build:/build -it builder
