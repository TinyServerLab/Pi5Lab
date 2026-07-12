# Episode 1 — Pi 5 First-Boot Setup (Headless)

Goal: from empty microSD to SSH-reachable Pi in ~15 minutes. No monitor or keyboard needed.

## 1. Flash the OS

1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
2. Choose: **Raspberry Pi 5 → Raspberry Pi OS Lite (64-bit)**
   - Lite = no desktop. We're building a server; a desktop just wastes RAM.
3. Click "Edit Settings" before writing:
   - **Hostname:** `pi5lab`
   - **Enable SSH** → *Allow public-key authentication only* (paste your public key)
   - **Username/password:** pick a non-default username (NOT `pi`)
   - **Configure WiFi** only if you can't use Ethernet (Ethernet strongly preferred for a server)
   - **Locale:** set your timezone (e.g. `Asia/Kolkata`)

> Don't have an SSH key yet? On your laptop: `ssh-keygen -t ed25519` then copy
> the contents of `~/.ssh/id_ed25519.pub` into the Imager settings.

## 2. Hardware checklist

- Attach the **official active cooler** before first boot — the Pi 5 thermal-throttles hard without it
- Use the official 27W USB-C PSU (underpowered supplies cause random USB/SSD failures)
- Plug into Ethernet if at all possible

## 3. First login

```bash
ssh youruser@pi5lab.local
# or find the IP from your router and: ssh youruser@192.168.x.x
```

## 4. First commands

```bash
sudo apt update && sudo apt full-upgrade -y
sudo reboot
```

After reboot, verify temperature and throttling status:

```bash
vcgencmd measure_temp      # should idle around 45-55°C with the active cooler
vcgencmd get_throttled     # 0x0 means never throttled — anything else, fix cooling/power
```

Next: [Harden your Pi](01-hardening.md)
