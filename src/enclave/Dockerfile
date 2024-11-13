FROM python:3.11.10-slim-bookworm@sha256:5148c0e4bbb64271bca1d3322360ebf4bfb7564507ae32dd639322e4952a6b16

ARG SOURCE_DATE_EPOCH

WORKDIR /app

COPY --chmod=0644 requirements.txt .

RUN pip install --require-hashes -r requirements.txt && \
    rm -rf /root/.cache/pip

COPY --chmod=0644 server.py .