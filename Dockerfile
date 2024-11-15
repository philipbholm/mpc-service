FROM golang:1.22 AS builder

WORKDIR /

RUN git clone https://github.com/brave/nitriding-daemon.git
RUN ARCH=arm64 make -C nitriding-daemon/ nitriding


FROM python:3.11.10-slim-bookworm@sha256:5148c0e4bbb64271bca1d3322360ebf4bfb7564507ae32dd639322e4952a6b16

ARG SOURCE_DATE_EPOCH

WORKDIR /app

COPY --from=builder /nitriding-daemon/nitriding /bin/

COPY --chmod=0644 requirements.txt .

RUN pip install -r requirements.txt && \
    rm -rf /root/.cache/pip

COPY --chmod=0755 src/main.py start.sh ./

CMD ["nitriding", "-fqdn", "example.com", "-appcmd", "python main.py", "-debug"]