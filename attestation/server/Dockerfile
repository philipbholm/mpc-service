FROM python:3.11.10-slim-bookworm

WORKDIR /app

COPY --chmod=0755 server.py proxy.py run.sh ./

CMD ["/app/run.sh"]