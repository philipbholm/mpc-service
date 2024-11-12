#!/bin/bash

set -e 

VERSION_STRING=5:20.10.13~3-0~ubuntu-jammy

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install docker and git
sudo apt-get install -y \
    docker-ce=$VERSION_STRING \
    docker-ce-cli=$VERSION_STRING \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    git-all

# Make docker available to non-root
sudo usermod -aG docker $USER

# Clone repo
git clone https://github.com/philipbholm/mpc-service.git

# Create aliases
echo "alias build='docker buildx --builder repro build -t server --platform linux/arm64 --build-arg SOURCE_DATE_EPOCH=0 --output type=docker,dest=server.tar,rewrite-timestamp=true src/enclave && docker load -i server.tar && sha256sum server.tar'" >> .bashrc
echo "alias start='docker buildx --builder repro build -t server --platform linux/arm64 --build-arg SOURCE_DATE_EPOCH=0 --output type=docker,dest=server.tar,rewrite-timestamp=true src/enclave && docker load -i server.tar && docker run --rm -it server /bin/bash'" >> .bashrc
echo "alias prep='docker buildx create --driver=docker-container --driver-opt image=moby/buildkit:v0.17.0 --name repro && docker build -t builder --platform linux/arm64 .'" >> .bashrc
echo "alias eif='docker buildx --builder repro build -t server --platform linux/arm64 --build-arg SOURCE_DATE_EPOCH=0 --output type=docker,dest=server.tar,rewrite-timestamp=true src/enclave && docker load -i server.tar && docker run --rm --platform linux/arm64 -v /var/run/docker.sock:/var/run/docker.sock builder'" >> .bashrc
echo "alias eifnc='docker buildx --builder repro build -t server --platform linux/arm64 --no-cache --build-arg SOURCE_DATE_EPOCH=0 --output type=docker,dest=server.tar,rewrite-timestamp=true src/enclave && docker load -i server.tar && docker run --rm --platform linux/arm64 -v /var/run/docker.sock:/var/run/docker.sock builder'" >> .bashrc

# Reboot for docker changes to take effect
sudo reboot