# Vaultwarden — Your Passwords, Your Hardware

📺 Episode: 🔗

Bitwarden-compatible server. All official Bitwarden apps and browser extensions
work with it — the data just lives on your Pi instead of someone's cloud.

## Deploy

```bash
cp .env.example .env    # generate ADMIN_TOKEN: openssl rand -base64 48
docker compose up -d
sudo ufw allow 8083/tcp
```

1. Open `http://<pi-ip>:8083`, create your account
2. Set `SIGNUPS_ALLOWED: "false"` in the compose file, then `docker compose up -d` again

## ⚠️ Two things that actually matter

**HTTPS:** Bitwarden clients refuse plain HTTP for anything except localhost.
For real use pair this with Tailscale (easiest) or a reverse proxy with TLS —
that's the second half of the episode.

**Backups:** your passwords now live in `./data/vaultwarden`. Back that folder up
off-Pi on a schedule. A password manager without backups is a time bomb:

```bash
tar czf vaultwarden-backup-$(date +%F).tgz ./data/vaultwarden
```
