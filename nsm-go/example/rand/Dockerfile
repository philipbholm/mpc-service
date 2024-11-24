FROM golang:1.17.2-buster

WORKDIR /build

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o enclave main.go

FROM scratch

COPY --from=0 /build/enclave ./

CMD ["/enclave"]