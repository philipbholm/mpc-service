FROM python:3.11.10-slim-bookworm

WORKDIR /app

COPY --chmod=0644 requirements.txt .

RUN pip install -r requirements.txt && \
    rm -rf /root/.cache/pip

COPY --chmod=0755 server.py proxy.py run.sh libnsm.so ./

CMD ["/app/run.sh"]