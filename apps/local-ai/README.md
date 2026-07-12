# Local AI — ChatGPT-Style Assistant, Fully Offline

📺 Episode: 🔗

Ollama runs the model; Open WebUI gives you a polished chat interface.
Nothing leaves your network.

## Requirements

- Pi 5 with **8 GB RAM** (4 GB will struggle even with tiny models)
- ~5 GB free disk per model

## Deploy

```bash
docker compose up -d
sudo ufw allow 8085/tcp
```

Pull a small model (do this once):

```bash
docker exec -it ollama ollama pull llama3.2:1b     # fastest on Pi
docker exec -it ollama ollama pull qwen2.5:1.5b    # good multilingual option
```

UI: `http://<pi-ip>:8085` — first account created becomes admin.

## Expectations (the honest part of the episode)

- 1B–2B models: usable, a few tokens per second — fine for chat, summaries, quick questions
- 7B+ models: technically load, painfully slow — don't bother on a Pi
- The magic isn't speed, it's **privacy + ₹0/month** — that's the video's angle
