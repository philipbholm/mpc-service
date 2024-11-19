#!/bin/sh

# Assign an IP address to local loopback
ip link set lo up
ip addr add 127.0.0.1/8 dev lo

python /app/proxy.py 443 3 8000 &
python /app/server.pys