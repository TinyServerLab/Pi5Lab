# Episode 6 — Cloudflare Tunnel (HTTPS + Zero Port Forwarding)
 
Access your Pi from anywhere in the world with a real HTTPS certificate. No port-forwarding. No exposed ports. No router configuration nightmare.
 
## The Promise
 
Instead of this:
```
expense.tinyserverlab.in → open port 8085 on router → forward to 192.168.1.50:8085
(+ security risks, + certificate headaches, + ISP can see all traffic)
```
 
You get this:
```
expense.tinyserverlab.in → Cloudflare Tunnel → Pi (localhost:8085, internal only)
(+ free HTTPS, + Pi invisible to internet, + ISP sees encrypted tunnel, + done)
```
 
## Prerequisites
 
- Cloudflare account (free tier is enough — log in at cloudflare.com)
- Your `tinyserverlab.in` domain pointed to Cloudflare nameservers
  - Done during domain registration or in your registrar's DNS settings
  - Verify: `dig tinyserverlab.in NS` should show Cloudflare nameservers
- Your Pi with Docker running (Episodes 1–5 complete)
- SSH access to the Pi
## Part 1 — Install Cloudflared
 
```bash
# SSH into your Pi
ssh youruser@pi5lab.local
 
# Download the ARM64 cloudflared package
curl -L --output cloudflared.deb \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
 
# Install it
sudo dpkg -i cloudflared.deb
 
# Clean up
rm cloudflared.deb
 
# Verify
cloudflared --version
```
 
Output should show: `cloudflared version X.X.X (built YYYY-MM-DD)` or similar.
 
## Part 2 — Authenticate with Cloudflare
 
```bash
# Start the login flow
cloudflared tunnel login
```
 
A long URL prints. Copy it, paste in your browser, and:
1. Log in to your Cloudflare account
2. Select your domain (`tinyserverlab.in`)
3. Click "Authorize"
The browser shows: "You have successfully authenticated Cloudflared."
 
Your Pi now has a certificate file at `~/.cloudflared/cert.pem`.
 
## Part 3 — Create the Tunnel
 
```bash
# Create a tunnel named 'tinyserverlab'
cloudflared tunnel create tinyserverlab
```
 
Output looks like:
```
Tunnel credentials written to /home/youruser/.cloudflared/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX.json
Cloudflare dashboard: https://dash.cloudflare.com/cgi-bin/manage/accounts/...
```
 
**Save the UUID** (the long hex string in the filename) — you'll need it in the next step.
 
## Part 4 — Configure Tunnel Routes
 
Create the Cloudflared config file:
 
```bash
nano ~/.cloudflared/config.yml
```
 
Paste this template. **Replace `TUNNEL-UUID` with your actual UUID from Step 3:**
 
```yaml
# Cloudflare Tunnel configuration for TinyServerLab
tunnel: tinyserverlab
credentials-file: /home/youruser/.cloudflared/TUNNEL-UUID.json
protocol: http2
 
# Logging
logpixel: false
loglevel: info
 
# Routing rules — specific hostnames first, catch-all last
ingress:
  # ===== APPS (add yours as you build them) =====
  - hostname: expense.tinyserverlab.in
    service: http://127.0.0.1:8085
 
  - hostname: meal.tinyserverlab.in
    service: http://127.0.0.1:8086
 
  - hostname: chore.tinyserverlab.in
    service: http://127.0.0.1:8087
 
  # ===== INFRASTRUCTURE =====
  - hostname: pihole.tinyserverlab.in
    service: http://127.0.0.1:8081
 
  - hostname: vault.tinyserverlab.in
    service: http://127.0.0.1:8083
 
  - hostname: media.tinyserverlab.in
    service: http://127.0.0.1:8096
 
  - hostname: monitor.tinyserverlab.in
    service: http://127.0.0.1:8084
 
  - hostname: speed.tinyserverlab.in
    service: http://127.0.0.1:8082
 
  - hostname: ai.tinyserverlab.in
    service: http://127.0.0.1:8085
 
  # ===== CATCH-ALL (must be last) =====
  - service: http_status:404
```
 
Save: Ctrl+X → Y → Enter.
 
**Key rules:**
- Each app gets its own line: `hostname:` → `service:` pointing to localhost
- Hostnames are in order of specificity (specific first, wildcards later, catch-all last)
- localhost ports (`8081`, `8085`, etc.) must match your Docker Compose bindings
- The catch-all `http_status:404` handles any unmapped subdomain
## Part 5 — Update Docker Compose Files to Bind Localhost Only
 
For **every app**, change the port binding from `"8085:5000"` to `"127.0.0.1:8085:5000"`.
 
This makes the port **invisible to your LAN** — only Cloudflared (running on the same Pi) can reach it.
 
### Example: Expense Tracker
 
**Before:**
```yaml
ports:
  - "8085:5000"    # Exposed to entire LAN
```
 
**After:**
```yaml
ports:
  - "127.0.0.1:8085:5000"    # Only localhost can access
```
 
### Apply to All Apps
 
Run this for each compose file:
 
```bash
# Expense Tracker
cd ~/pi5-lab/apps/expense-tracker
sed -i 's/"8085:/"127.0.0.1:8085:/g' docker-compose.yml
 
# Meal Planner
cd ~/pi5-lab/apps/meal-planner
sed -i 's/"8086:/"127.0.0.1:8086:/g' docker-compose.yml
 
# (repeat for each app with its port)
```
 
Then restart all containers:
 
```bash
for app in expense-tracker meal-planner chore-tracker; do
  cd ~/pi5-lab/apps/$app
  docker compose up -d
done
```
 
Verify they restarted:
```bash
docker ps
```
 
---
 
## Part 6 — Run Cloudflared as a Systemd Service
 
```bash
# Install as a system service (survives reboots)
sudo cloudflared service install
 
# Start the tunnel
sudo systemctl start cloudflared
 
# Enable on boot
sudo systemctl enable cloudflared
 
# Check status
sudo systemctl status cloudflared
```
 
Output should show: `Active: active (running)` in green.
 
Watch the logs:
```bash
sudo journalctl -u cloudflared -f
```
 
You should see lines like:
```
INF Tunnel running
INF Registered ingress rule for expense.tinyserverlab.in
INF Registered ingress rule for meal.tinyserverlab.in
...
```
 
Press Ctrl+C to exit the logs.
 
---
 
## Part 7 — DNS Records in Cloudflare Dashboard
 
Log in to [dash.cloudflare.com](https://dash.cloudflare.com), select your domain.
 
### Option A: Wildcard (Recommended)
 
Go to **DNS** tab. Add one record:
 
| Type | Name | Target |
|------|------|--------|
| CNAME | `*.tinyserverlab.in` | `tinyserverlab.in` |
 
This single record routes **all subdomains** (expense.tinyserverlab.in, meal.tinyserverlab.in, etc.) through the tunnel.
 
### Option B: Individual Records (Explicit)
 
For each app, add:
 
| Type | Name | Target |
|------|------|--------|
| CNAME | `expense.tinyserverlab.in` | `tinyserverlab.in` |
| CNAME | `meal.tinyserverlab.in` | `tinyserverlab.in` |
| CNAME | `pihole.tinyserverlab.in` | `tinyserverlab.in` |
| (etc.) | | |
 
---
 
## Part 8 — Test It
 
Wait 2–5 minutes for DNS to propagate (even though it's usually instant).
 
### From Your Phone (Cellular Data)
 
Turn off WiFi so you're definitely not on your local network. Then:
 
```
Browser: https://expense.tinyserverlab.in
```
 
You should see:
- ✅ Valid HTTPS certificate (no warnings)
- ✅ Your app loads (the expense tracker, Pi-hole admin, whatever)
- ✅ Fully encrypted tunnel from phone → Cloudflare → Pi
### From Your Mac
 
```bash
# Test one app
curl https://expense.tinyserverlab.in
 
# Test the admin panel
curl https://pihole.tinyserverlab.in/admin
 
# Check the tunnel status
cloudflared tunnel info tinyserverlab
```
 
---
 
## Troubleshooting
 
### "Connection Refused" or App Doesn't Load
 
**Check 1:** Is the app actually running?
```bash
docker ps | grep expense-tracker
```
 
If not listed, start it:
```bash
cd ~/pi5-lab/apps/expense-tracker
docker compose up -d
```
 
**Check 2:** Is Cloudflared running?
```bash
sudo systemctl status cloudflared
```
 
If not active, restart it:
```bash
sudo systemctl restart cloudflared
sudo journalctl -u cloudflared -f    # Watch logs for errors
```
 
**Check 3:** Does the port binding match the config?
 
In `docker-compose.yml`:
```yaml
ports:
  - "127.0.0.1:8085:5000"
```
 
In `~/.cloudflared/config.yml`:
```yaml
- hostname: expense.tinyserverlab.in
  service: http://127.0.0.1:8085
```
 
Port `8085` must match on both sides.
 
**Check 4:** DNS propagation
 
```bash
# Verify the subdomain resolves
dig expense.tinyserverlab.in
 
# Should show CNAME to tinyserverlab.in
```
 
If it doesn't, wait another minute or refresh your Cloudflare DNS cache.
 
### "Invalid Certificate" Warning
 
Cloudflare automatically provisions and renews certificates. If you see a warning:
 
1. Hard-refresh the browser (Ctrl+Shift+R on Windows/Linux, Cmd+Shift+R on Mac)
2. If still failing, restart the tunnel:
```bash
   sudo systemctl restart cloudflared
```
3. Wait 30 seconds and try again
---
 
## Local Network Access (Home WiFi)
 
Viewers on your home WiFi don't *need* the tunnel — they can still access apps by IP:
 
```
http://192.168.1.50:8085    → Expense Tracker (if you expose the port, which you don't)
```
 
Since we bound to `127.0.0.1`, apps are **invisible to LAN by design** — which is secure but limits local access.
 
### Optional: Enable Local Access
 
If you want family on your WiFi to access apps by hostname, set up **local DNS** via Pi-hole:
 
1. Go to Pi-hole admin: `http://pi5lab.local:8081/admin` (or the Cloudflare tunnel one)
2. **Settings → Local DNS Records**
3. Add: `expense.local` → `192.168.1.50` (your Pi's IP)
4. Repeat for each app
Then from home WiFi:
```
http://expense.local:8085
```
 
Cloudflared tunnel remains your **external-only** access (from internet).
 
---
 
## Monitoring & Logs
 
### Real-Time Tunnel Activity
 
```bash
# Follow the tunnel logs live
sudo journalctl -u cloudflared -f
```
 
Watch for request lines like:
```
INF 2026-07-25 14:32:15.123Z [expense.tinyserverlab.in] GET /
INF 2026-07-25 14:32:16.456Z [pihole.tinyserverlab.in] GET /admin
```
 
### Check Tunnel Health
 
```bash
cloudflared tunnel info tinyserverlab
```
 
Shows: active routes, last heartbeat, account info.
 
### Check Account Limits
 
Cloudflare free tier:
- ✅ Unlimited tunnels
- ✅ Unlimited traffic
- ✅ Free HTTPS certificates
- ✅ Free DDoS protection
- ⚠️ No custom analytics (paid tiers add that)
---
 
## Security Notes
 
**What Cloudflare Tunnel Protects:**
 
✅ Your Pi's IP is never exposed to the internet
✅ No open ports on your router (no port-forwarding needed)
✅ All traffic is encrypted (TLS to Cloudflare, then encrypted to Pi)
✅ ISP can't see which apps you access (only that you're talking to Cloudflare)
✅ DDoS protection built-in (Cloudflare absorbs attacks before they reach you)
✅ HTTPS certificates auto-renewed
 
**What It Doesn't Protect:**
 
⚠️ Your apps still need strong passwords (use Vaultwarden for shared login)
⚠️ Apps need to be kept updated (Docker `pull` regularly)
⚠️ Database backups are still your job (app data lives in `./data/` folders)
 
---
 
## Next Steps
 
1. ✅ Deploy more apps (Vaultwarden, Jellyfin, Ollama, etc.)
2. ✅ Each new app: add to `config.yml`, update its `docker-compose.yml` port binding, restart tunnel
3. ✅ Set up local DNS in Pi-hole for home WiFi access
4. ✅ Bookmark `https://pihole.tinyserverlab.in/admin` for remote ad-blocker management
5. ✅ Share `https://vault.tinyserverlab.in` with family (after setting up accounts)
---
 
## Rollback / Disable Tunnel
 
If you ever want to disable external access:
 
```bash
# Stop the service
sudo systemctl stop cloudflared
 
# Disable on boot
sudo systemctl disable cloudflared
 
# Remove it entirely
sudo cloudflared service uninstall
```
 
Local WiFi access by IP still works. Just delete the DNS records in Cloudflare if you don't want the subdomains published.
 
---
 
**Previous:** [Hardening Your Pi](01-hardening.md)
**Next:** Build your first 30-minute challenge app