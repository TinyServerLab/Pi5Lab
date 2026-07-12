# Pi-hole — Block Ads on Every Device

📺 Episode: 🔗 (link after publish)

## Before you start

Port 53 must be free. Raspberry Pi OS Lite usually has nothing on it, but if
`sudo ss -lunp | grep :53` shows `systemd-resolved` or `dnsmasq`, disable it first
(covered in the episode).

## Deploy

```bash
cp .env.example .env    # set your password
docker compose up -d
sudo ufw allow 53       # DNS from your LAN
sudo ufw allow 8081/tcp # admin UI
```

Admin UI: `http://<pi-ip>:8081/admin`

## Point your network at it

Best: set your **router's DHCP DNS server** to the Pi's IP — every device on the
network is covered automatically. Alternative: set DNS manually per device.

> 💡 Give your Pi a static IP / DHCP reservation first, or DNS breaks when the Pi's IP changes.

## Verify it's working

```bash
dig @<pi-ip> doubleclick.net   # should return 0.0.0.0
```

Then open the admin dashboard and watch the blocked-query counter climb.
