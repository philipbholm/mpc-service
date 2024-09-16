FROM python:3.11.10-alpine3.20@sha256:004b4029670f2964bb102d076571c9d750c2a43b51c13c768e443c95a71aa9f3

ARG SOURCE_DATE_EPOCH

WORKDIR /app

COPY requirements.txt .

RUN pip install --require-hashes --no-cache-dir -r requirements.txt

COPY server.py .

RUN days_ago=$((($(date +%s) - ${SOURCE_DATE_EPOCH}) / 86400 + 1)) && \
    find / -xdev \( -path /dev -o -path /mnt -o -path /proc -o -path /sys -o -path /etc/hosts -o -path /etc/resolv.conf \) -prune -o -type f -mtime -${days_ago} -print0 \
    | xargs -0 -r touch --date="@${SOURCE_DATE_EPOCH}" --no-dereference

FROM scratch
COPY --from=0 / /

CMD ["/usr/local/bin/python3", "server.py"]
