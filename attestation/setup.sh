#!/bin/bash

# Manual steps
# sudo dnf -y install git-all
# git clone https://github.com/philipbholm/mpc-service.git

# Install dependencies
sudo dnf -y install aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel

# Update user permissions
sudo usermod -aG ne ec2-user && sudo usermod -aG docker ec2-user

# Allocate resources to enclave 
# Leaves 1 vCPU and 4096 GiB RAM for the parent
MEMORY_AVAILABLE=$(awk '/MemTotal/ {printf "%d", $2/4096 - 4096}' /proc/meminfo)
CPU_AVAILABLE=$(($(nproc) - 1))
sudo sed -i "s/^memory_mib:.*/memory_mib: ${MEMORY_AVAILABLE}/" /etc/nitro_enclaves/allocator.yaml
sudo sed -i "s/^cpu_count:.*/cpu_count: ${CPU_AVAILABLE}/" /etc/nitro_enclaves/allocator.yaml

# Enable and start services
sudo systemctl enable --now docker
sudo systemctl enable --now nitro-enclaves-allocator.service
sudo systemctl enable --now nitro-enclaves-vsock-proxy.service

# Aliases
echo "alias stop='nitro-cli terminate-enclave --all'" >> ~/.bashrc
echo "alias desc='nitro-cli describe-enclaves'" >> ~/.bashrc

# Install tmux 
sudo dnf install -y tmux 

sudo reboot