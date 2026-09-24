#!/bin/bash
# Creates one role + one database per application on the shared Postgres.
#
# Idempotent: an existing role or database is left untouched (no password
# reset, no owner change), so this is safe to re-run by hand after adding a
# new app to .env:
#   docker exec shared-postgres-dbs bash /docker-entrypoint-initdb.d/01-init-databases.sh
#
# Note: the postgres image only runs this automatically on the FIRST start
# (empty data volume). Later changes to .env are NOT applied — re-run it
# manually as above, or ALTER ROLE for password changes (see README.md).
set -euo pipefail

# One prefix per app: POSTGRES_<PREFIX>_DB / _USER / _PASSWORD in .env.
# Add a prefix here + its three vars in .env to onboard a new app.
APPS=(FT LEDGER NSE)

psql_admin() {
  psql -v ON_ERROR_STOP=1 -qtA --username "$POSTGRES_USER" --dbname postgres "$@"
}

valid_ident() {
  [[ "$1" =~ ^[a-z_][a-z0-9_]{0,62}$ ]]
}

for app in "${APPS[@]}"; do
  db_var="POSTGRES_${app}_DB"
  user_var="POSTGRES_${app}_USER"
  pass_var="POSTGRES_${app}_PASSWORD"
  db="${!db_var:-}"
  user="${!user_var:-}"
  pass="${!pass_var:-}"

  if [[ -z "$db" && -z "$user" ]]; then
    echo "[init-db] ${app}: not configured in .env — skipped"
    continue
  fi
  if [[ -z "$db" || -z "$user" ]]; then
    echo "[init-db] ${app}: both ${db_var} and ${user_var} must be set" >&2
    exit 1
  fi
  for name in "$db" "$user"; do
    if ! valid_ident "$name"; then
      echo "[init-db] ${app}: '${name}' is not a valid name (use lowercase letters, digits, _)" >&2
      exit 1
    fi
  done

  # --- role ---
  role_exists=$(psql_admin -v name="$user" <<< "SELECT 1 FROM pg_roles WHERE rolname = :'name';")
  if [[ "$role_exists" == "1" ]]; then
    echo "[init-db] ${app}: role '${user}' already exists — left unchanged"
  else
    if [[ -z "$pass" ]]; then
      echo "[init-db] ${app}: ${pass_var} must be set to create role '${user}'" >&2
      exit 1
    fi
    psql_admin -v u="$user" -v p="$pass" <<< "CREATE ROLE :\"u\" LOGIN PASSWORD :'p';"
    echo "[init-db] ${app}: role '${user}' created"
  fi

  # --- database ---
  db_exists=$(psql_admin -v name="$db" <<< "SELECT 1 FROM pg_database WHERE datname = :'name';")
  if [[ "$db_exists" == "1" ]]; then
    echo "[init-db] ${app}: database '${db}' already exists — left unchanged"
  else
    # CREATE DATABASE cannot run inside a transaction, so keep statements separate.
    # Revoking PUBLIC connect keeps each app out of the other apps' databases.
    psql_admin -v d="$db" -v u="$user" <<-'EOSQL'
		CREATE DATABASE :"d" OWNER :"u";
		REVOKE ALL ON DATABASE :"d" FROM PUBLIC;
		GRANT CONNECT, TEMPORARY ON DATABASE :"d" TO :"u";
	EOSQL
    echo "[init-db] ${app}: database '${db}' created (owner '${user}')"
  fi
done
