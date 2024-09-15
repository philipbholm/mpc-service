FROM python:3.11.10-alpine3.20@sha256:004b4029670f2964bb102d076571c9d750c2a43b51c13c768e443c95a71aa9f3

WORKDIR /app

COPY requirements.txt .

RUN pip install --require-hashes --no-cache-dir -r requirements.txt

COPY server.py .

CMD ["/usr/local/bin/python3", "server.py"]
