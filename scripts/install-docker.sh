#!/usr/bin/env bash
# Pi5 Lab — Episode 3: install Docker Engine + Compose plugin on Raspberry Pi OS (64-bit).
set -euo pipefail

if command -v docker >/dev/null 2>&1; then
  echo "Docker already installed: $(docker --version)"
  exit 0
fi

echo "==> Installing Docker via the official convenience script"
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sudo sh /tmp/get-docker.sh
rm /tmp/get-docker.sh

echo "==> Adding $USER to the docker group"
sudo usermod -aG docker "$USER"

echo ""
echo "✅ Docker installed: $(docker --version 2>/dev/null || echo 'log out/in to use without sudo')"
echo "   Log out and back in (or run 'newgrp docker'), then verify with:"
echo "   docker run --rm hello-world"
