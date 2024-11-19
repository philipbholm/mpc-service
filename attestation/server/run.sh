#!/bin/sh

nohup python /app/proxy.py 443 3 8000 &
python /app/server.py