#!/bin/bash

set -e

PUBLIC_IP=$(tofu output -raw public_ip)

ssh -i ~/.ssh/mpc-key.pem ec2-user@$PUBLIC_IP
