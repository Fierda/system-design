#!/bin/bash
set -e

# Update & install dependencies
apt-get update -y
apt-get upgrade -y
apt-get install -y curl unzip wget

# === Install Node.js & PM2 ===
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs
npm install -g pm2

# === Install Go ===
GO_VERSION=1.21.0
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile
export PATH=$PATH:/usr/local/go/bin
