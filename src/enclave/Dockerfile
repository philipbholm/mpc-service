FROM python:3.11.10-alpine3.20@sha256:004b4029670f2964bb102d076571c9d750c2a43b51c13c768e443c95a71aa9f3

ARG SOURCE_DATE_EPOCH

WORKDIR /app

COPY requirements.txt .

RUN pip install --require-hashes --no-cache-dir -r requirements.txt

COPY server.py .

RUN touch -d "@${SOURCE_DATE_EPOCH}" /tmp/source_date_epoch && \
    find $( ls / | grep -E -v "^(dev|mnt|proc|sys)$" ) \
    -newer /tmp/source_date_epoch -perm -u+w 2>/dev/null -xdev \
    | xargs -r touch -h -d "@${SOURCE_DATE_EPOCH}"

FROM scratch
COPY --from=0 / /

CMD ["/usr/local/bin/python3", "server.py"]
