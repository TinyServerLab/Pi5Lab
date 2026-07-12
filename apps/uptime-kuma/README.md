# Uptime Kuma — Your Personal Status Page

📺 Episode: 🔗

Monitors anything — websites, your other Pi containers, your router, your blog —
and alerts you on Discord/Telegram/email when something goes down.

## Deploy

```bash
docker compose up -d
sudo ufw allow 8084/tcp
```

UI: `http://<pi-ip>:8084` — create your admin account on first visit.

## Great first monitors (used in the episode)

1. Your router (ping) — "is my internet even up?"
2. Every app from this repo (HTTP) — Pi-hole, Jellyfin, Vaultwarden…
3. Your public website/blog (HTTP + keyword check)
4. Discord webhook notifications — down alerts straight to your phone

No `.env` needed for this one — simplest deploy in the whole series.
