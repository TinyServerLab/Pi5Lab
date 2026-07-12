# Episode 3 — Docker on the Pi 5

Automated in [`scripts/install-docker.sh`](../scripts/install-docker.sh).

## Install (official convenience script)

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker   # or log out and back in
```

Verify:

```bash
docker --version
docker compose version
docker run --rm hello-world
```

## Why Compose files instead of `docker run`?

- The file **is** the documentation — you can read exactly what's deployed
- `docker compose up -d` after a reboot/rebuild restores everything
- Upgrades are two commands: `docker compose pull && docker compose up -d`

## The layout used in every episode

```
apps/<app>/
├── docker-compose.yml   # the stack definition (committed to git)
├── .env.example         # template for secrets (committed)
├── .env                 # your real secrets (NEVER committed)
└── data/                # app state (created at first run, git-ignored)
```

## Housekeeping commands you'll use constantly

```bash
docker compose logs -f                        # tail logs for the current stack
docker compose pull && docker compose up -d   # upgrade
docker system prune                           # reclaim disk from old images
docker stats                                  # live CPU/RAM per container
```

Now pick your first app — [`apps/pihole`](../apps/pihole) is the classic starting point.
