FROM debian:12.7-slim@sha256:ad86386827b083b3d71139050b47ffb32bbd9559ea9b1345a739b14fec2d9ecf

ARG SOURCE_DATE_EPOCH

RUN \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache && \
    sed -i 's|http://deb.debian.org/debian-security|http://snapshot.debian.org/archive/debian-security/20240926T000000Z|' /etc/apt/sources.list.d/debian.sources && \
    sed -i 's|http://deb.debian.org/debian|http://snapshot.debian.org/archive/debian/20240926T000000Z|' /etc/apt/sources.list.d/debian.sources && \
    sed -i '/^Signed-By:/a check-valid-until: no' /etc/apt/sources.list.d/debian.sources && \
    apt update && \
    apt install -y python3 python3-pip python3-venv && \
    rm -rf /var/log/* /var/cache/ldconfig/aux-cache

COPY requirements.txt .

RUN \
    python3 -m venv venv && \
    venv/bin/pip3 install --require-hashes --no-cache-dir -r requirements.txt

COPY server.py .

RUN find $( ls / | grep -E -v "^(dev|mnt|proc|sys)$" ) \
    -xdev -writable -newermt "@${SOURCE_DATE_EPOCH}" \
    | xargs -d '\n' touch --date="@${SOURCE_DATE_EPOCH}" --no-dereference

FROM scratch
COPY --from=0 / /

CMD ["/usr/bin/python3", "server.py"]
