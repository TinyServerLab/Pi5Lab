#!/bin/bash
set -euo pipefail

echo "==> Installing Cloudflared"
curl -L --output /tmp/cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
sudo dpkg -i /tmp/cloudflared.deb
rm /tmp/cloudflared.deb

echo "✅ Cloudflared installed: $(cloudflared --version)"
echo ""
echo "Next: run 'cloudflared tunnel login' to authenticate"