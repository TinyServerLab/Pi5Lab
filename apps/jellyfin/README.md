# Jellyfin — Netflix, but It's Your Files

📺 Episode: 🔗

## Before you deploy

Put media on an external SSD, not the microSD card. Mount it (e.g. at `/mnt/ssd`)
and organize as:

```
/mnt/ssd/media/
├── Movies/
│   └── Movie Name (2024)/Movie Name (2024).mkv
└── Shows/
    └── Show Name/Season 01/Show Name S01E01.mkv
```

Naming matters — Jellyfin's metadata matching depends on it.

## Deploy

```bash
cp .env.example .env    # set MEDIA_PATH
docker compose up -d
sudo ufw allow 8096/tcp
```

Setup wizard: `http://<pi-ip>:8096` — add `/media` as your library path.

## Pi 5 performance reality check

- **Direct play** (client supports the codec): Pi 5 handles multiple streams easily
- **Transcoding** is the Pi's weak spot — enable hardware acceleration
  (Dashboard → Playback → V4L2) and prefer H.264 files or clients that direct-play
- Jellyfin apps exist for Android/iOS/TV — same episode, big "wow" moment
