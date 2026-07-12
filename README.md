# 🥧 TinyServerLab — Pi5 Lab Series

**Self-Hosted Apps on Raspberry Pi 5** · [YouTube](https://youtube.com/@TinyServerLab) · [tinyserverlab.in](https://tinyserverlab.in)

Raspberry Pi5 gear setup and self hosting application

Copy-paste Docker Compose configs from the **Pi5 Lab** series on the TinyServerLab channel. Every app here runs on a
Raspberry Pi 5 (ARM64) and takes **under 5 minutes** to deploy once Docker is installed.

> 📺 **Watch the series:** [youtube.com/@TinyServerLab](https://youtube.com/@TinyServerLab)
> Each app folder links to its episode.

## What's inside

| # | App | Replaces | Folder | Episode |
|---|-----|----------|--------|---------|
| 1 | Pi-hole | Ad blockers on every device | [`apps/pihole`](apps/pihole) | 🔗 |
| 2 | Speedtest Tracker | Manually checking your ISP | [`apps/speedtest-tracker`](apps/speedtest-tracker) | 🔗 |
| 3 | Vaultwarden | Password manager subscription | [`apps/vaultwarden`](apps/vaultwarden) | 🔗 |
| 4 | Jellyfin | Streaming subscriptions | [`apps/jellyfin`](apps/jellyfin) | 🔗 |
| 5 | Uptime Kuma | Paid uptime monitors | [`apps/uptime-kuma`](apps/uptime-kuma) | 🔗 |
| 6 | Ollama + Open WebUI | ChatGPT subscription | [`apps/local-ai`](apps/local-ai) | 🔗 |

## Start here (in order)

1. **[Pi 5 first-boot setup](docs/00-pi5-setup.md)** — flash, headless SSH, cooling
2. **[Harden your Pi](docs/01-hardening.md)** — or run [`scripts/harden.sh`](scripts/harden.sh)
3. **[Install Docker](docs/02-docker-install.md)** — or run [`scripts/install-docker.sh`](scripts/install-docker.sh)
4. Pick any app folder and follow its README

## Quick deploy (any app)

```bash
cd apps/<app-name>
cp .env.example .env        # edit values first!
docker compose up -d
```

## Hardware used in the series

- Raspberry Pi 5 (8 GB recommended, 4 GB works for everything except local AI)
- Official active cooler (don't skip this — the Pi 5 throttles without it)
- A2-rated microSD (boot) + USB/NVMe SSD for app data (recommended)

## Conventions

- All app data lives in `./data` next to each compose file — back up one folder, keep everything
- Every stack uses `restart: unless-stopped` so apps survive reboots
- Secrets go in `.env` files, which are **git-ignored** — never commit them
- Images are pinned to major versions where the project supports it

## Contributing / Requests

Open an issue with the app you want covered next, or comment on any episode.

## License

MIT — use these configs however you like.
