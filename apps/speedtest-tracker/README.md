# Speedtest Tracker — Is Your ISP Delivering What You Pay For?

📺 Episode: 🔗

Runs a speed test every hour and graphs the history. When your "100 Mbps plan"
dips to 20 Mbps every evening, you'll have the data to prove it.

## Deploy

```bash
cp .env.example .env
# generate the APP_KEY:
echo -n 'base64:'; openssl rand -base64 32
# paste result into .env, set PI_IP, then:
docker compose up -d
sudo ufw allow 8082/tcp
```

UI: `http://<pi-ip>:8082` — default login is shown once in the container logs:

```bash
docker compose logs | grep -iA2 'admin'
```

## Tune it

- `SPEEDTEST_SCHEDULE` is standard cron — `"*/30 * * * *"` for every 30 min
- Don't schedule tests more often than every 15 min; it saturates your own link
- Notifications (Telegram/Discord/email) are configurable in Settings — great episode moment
