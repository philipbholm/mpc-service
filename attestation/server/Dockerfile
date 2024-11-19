FROM python:3.11.10-alpine3.20

WORKDIR /app

COPY --chmod=0755 server.py proxy.py run.sh ./

CMD ["/app/run.sh"]