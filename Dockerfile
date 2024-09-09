FROM public.ecr.aws/amazonlinux/amazonlinux:2

RUN amazon-linux-extras install aws-nitro-enclaves-cli
RUN yum install aws-nitro-enclaves-cli-devel -y

WORKDIR /build

CMD ["/bin/bash", "-c", "nitro-cli build-enclave --docker-uri server --output-file server.eif"]
