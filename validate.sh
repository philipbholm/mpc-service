#!/bin/bash

docker build -t enclave_base --no-cache src/enclave/base_image
docker build -t server --no-cache src/enclave

cat > Dockerfile <<EOF
FROM amazonlinux:2

RUN amazon-linux-extras install aws-nitro-enclaves-cli
RUN yum install -y aws-nitro-enclaves-cli-devel

WORKDIR /build

CMD ["/bin/bash", "-c", "nitro-cli build-enclave --docker-uri server --output-file server.eif"]
EOF

docker build -t builder --no-cache .
docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/build:/build -it builder
