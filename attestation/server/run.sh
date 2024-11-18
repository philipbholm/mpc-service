#!/bin/sh

# Assign an IP address to local loopback
ip link set lo up
ip addr add 127.0.0.1/8 dev lo

# Add a hosts record, pointing API endpoint to local loopback
echo "127.0.0.1   kms.us-east-1.amazonaws.com" >> /etc/hosts

nohup python3 /app/proxy.py 443 3 8000 &
python3 /app/server.py