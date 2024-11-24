FROM golang:1.17.2-buster

WORKDIR /

RUN mkdir -p source

COPY . ./source/

WORKDIR source/example/att

RUN CGO_ENABLED=0 GOOS=linux go build -o enclave main.go

FROM scratch

WORKDIR /

COPY --from=0 /source/example/att/enclave ./

CMD ["/enclave"]

