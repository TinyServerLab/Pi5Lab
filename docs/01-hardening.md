# Episode 2 — Hardening Your Pi

Your Pi will run 24/7 on your network. Ten minutes of hardening now saves you a
compromised home network later. Everything below is automated in
[`scripts/harden.sh`](../scripts/harden.sh) — this doc explains *what* it does and *why*.

## 1. SSH: keys only, no root

Create `/etc/ssh/sshd_config.d/hardening.conf`:

```
PasswordAuthentication no
PermitRootLogin no
MaxAuthTries 3
```

Then `sudo systemctl restart ssh`.

> ⚠️ Confirm key-based login works in a SECOND terminal before closing your current one.

## 2. Firewall (UFW)

Deny everything inbound by default, allow only what you use:

```bash
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable
```

You'll open app ports per-episode as needed (each app README lists its ports).

> 🧠 Gotcha we cover in the episode: Docker publishes ports via iptables and can
> bypass UFW for containers. Rule of thumb — bind admin-only services to
> `127.0.0.1:port:port` in compose, and keep the Pi off any port-forwarded/DMZ setup.

## 3. Fail2ban

Bans IPs that brute-force SSH:

```bash
sudo apt install -y fail2ban
sudo systemctl enable --now fail2ban
```

## 4. Automatic security updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 5. Things NOT to do

- ❌ Don't port-forward your Pi to the internet "just to test" — use Tailscale/WireGuard for remote access (future episode)
- ❌ Don't run containers as `privileged` unless the app genuinely requires it
- ❌ Don't reuse your Pi password anywhere else (better: no passwords at all, keys only)

Next: [Install Docker](02-docker-install.md)
