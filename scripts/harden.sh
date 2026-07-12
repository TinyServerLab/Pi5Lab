#!/usr/bin/env bash
# Pi5 Lab — Episode 2: basic hardening for a fresh Raspberry Pi OS install.
# Run as your normal user: bash scripts/harden.sh
set -euo pipefail

echo "==> Pi5 Lab hardening script"
echo "    This will: lock down SSH, enable UFW + fail2ban, enable auto security updates."
read -rp "Continue? [y/N] " ans
[[ "${ans,,}" == "y" ]] || exit 0

# --- Safety check: make sure at least one SSH key is authorized before disabling passwords
if [[ ! -s "$HOME/.ssh/authorized_keys" ]]; then
  echo "!! No SSH keys found in ~/.ssh/authorized_keys."
  echo "   Add your public key first, verify key login works, then re-run."
  exit 1
fi

echo "==> [1/4] Hardening SSH (keys only, no root login)"
sudo tee /etc/ssh/sshd_config.d/hardening.conf > /dev/null << 'CONF'
PasswordAuthentication no
PermitRootLogin no
MaxAuthTries 3
CONF
sudo systemctl restart ssh
echo "    Keep this session open and verify you can SSH in from a NEW terminal."

echo "==> [2/4] Installing and enabling UFW firewall"
sudo apt-get update -qq
sudo apt-get install -y -qq ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw --force enable

echo "==> [3/4] Installing fail2ban"
sudo apt-get install -y -qq fail2ban
sudo systemctl enable --now fail2ban

echo "==> [4/4] Enabling unattended security upgrades"
sudo apt-get install -y -qq unattended-upgrades
sudo systemctl enable --now unattended-upgrades

echo ""
echo "✅ Done. Summary:"
sudo ufw status verbose | sed 's/^/    /'
echo "    fail2ban: $(systemctl is-active fail2ban)"
echo ""
echo "Remember: open app ports with 'sudo ufw allow <port>/tcp' as each episode needs them."
