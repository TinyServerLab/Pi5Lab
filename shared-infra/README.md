# Shared Infra — Postgres + Caddy

One Postgres server and one Caddy reverse proxy shared by every app on the Pi,
instead of a database container and exposed port per app.

```
Cloudflare ─► cloudflared ─► 127.0.0.1:8080 ─► shared-caddy ──(shared-web)──► app containers
                                                                               │
                                               shared-postgres ◄─(shared-db)┘
```

| App             | URL                            | Caddy upstream               | Database      |
|-----------------|--------------------------------|------------------------------|---------------|
| Finance Tracker | `ft.tinyserverlab.in`          | `finance-app:8000`           | `finance_app` |
| Ledger          | `ledger.tinyserverlab.in`      | `ledger-app:8000`            | `ledger`      |
| NSE Signal      | `nse.tinyserverlab.in`         | `nse-signal-trader:8000`     | `nse_signal`  |
| NSE Dashboard   | `nse-dash.tinyserverlab.in`    | `nse-signal-dashboard:8501`  | (same)        |

Upstreams can be changed in `caddy/.env` without editing the Caddyfile.

## 1. Start (Postgres first; it creates the `shared-db` network)

```bash
cd postgres && cp .env.example .env && nano .env   # set real passwords
docker compose up -d && docker logs shared-postgres | grep init-db

cd ../caddy && cp .env.example .env
docker compose up -d
```

## 2. Wire an app in

In the app's `docker-compose.yml`: drop its own `postgres` service and its
`ports:` (Caddy reaches it on the network), then join both networks:

```yaml
services:
  app:
    container_name: finance-app          # must match the Caddy upstream
    environment:
      DATABASE_URL: postgresql://finance_app:<ft_password>@shared-postgres:5432/finance_app
    networks: [shared-db, shared-web]

networks:
  shared-db:  { external: true }
  shared-web: { external: true }
```

**nse-signal** already reads `DATABASE_URL` (SQLAlchemy), but it still defaults
to SQLite — switching needs a Postgres driver (`psycopg[binary]`) in
`requirements.txt` and a data migration from `data/nse_signal.db`. Both
`nse-signal` and `dashboard` services need the networks above.
`golden-master` keeps its own SQLite DB by design and needs neither.

## 3. Cloudflare Tunnel

Point every app hostname at Caddy in `~/.cloudflared/config.yml`:

```yaml
  - hostname: ft.tinyserverlab.in
    service: http://127.0.0.1:8080
  - hostname: ledger.tinyserverlab.in
    service: http://127.0.0.1:8080
  - hostname: nse.tinyserverlab.in
    service: http://127.0.0.1:8080
  - hostname: nse-dash.tinyserverlab.in
    service: http://127.0.0.1:8080
```

Then `cloudflared tunnel route dns tinyserverlab <hostname>` for each, and
`sudo systemctl restart cloudflared`.

## Init script behaviour

`postgres/init/01-init-databases.sh` runs automatically **only on the first
start** (empty `postgres_data` volume). It is idempotent: an existing role or
database is skipped and never modified — passwords are not reset.

- **Add an app later:** add `POSTGRES_<PREFIX>_*` to `.env`, add the prefix to
  `APPS=(...)` in the script, `docker compose up -d` (reloads env), then:
  `docker exec shared-postgres bash /docker-entrypoint-initdb.d/01-init-databases.sh`
- **Change an app password:** editing `.env` alone does nothing for an existing role.
  `docker exec -it shared-postgres psql -U pgadmin -d postgres -c "ALTER ROLE finance_app PASSWORD 'new';"`

## Restoring an old app dump

Restore **as the app role**, so the tables belong to the app and not to `pgadmin`:

```bash
# custom-format dump (.dump), into the empty app database
docker exec -i shared-postgres pg_restore -U pgadmin -d finance_app \
  --no-owner --no-privileges --role=finance_app < finance.dump

# plain SQL dump (.sql)
docker exec -i shared-postgres psql -U finance_app -d finance_app < finance.sql
```

Already restored as `pgadmin` and the app now gets `permission denied for table ...`?
Hand ownership back (no data is touched; safe to re-run):

```bash
docker exec -i shared-postgres bash -s -- finance_app finance_app < postgres/scripts/fix-ownership.sh
#                                         ^database   ^app role
```

## Backup

```bash
docker exec shared-postgres pg_dumpall -U pgadmin | gzip > pg-$(date +%F).sql.gz
```
