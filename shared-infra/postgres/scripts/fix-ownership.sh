#!/bin/bash
# Hands every object in an app database to the app role — fixes
# "permission denied for table ..." after a pg_restore run as the superuser
# (restored objects end up owned by pgadmin, not the app).
#
# Usage (on the Pi):
#   docker exec -i shared-postgres bash -s -- <database> <app_role> < postgres/scripts/fix-ownership.sh
#   e.g. ... -- finance_app finance_app
#
# Only changes ownership; no data is touched. Safe to re-run.
set -euo pipefail

db="${1:?usage: fix-ownership.sh <database> <app_role>}"
role="${2:?usage: fix-ownership.sh <database> <app_role>}"

psql -v ON_ERROR_STOP=1 -X --username "$POSTGRES_USER" --dbname "$db" -v role="$role" <<'EOSQL'
\set user_schema 'n.nspname NOT IN (''pg_catalog'', ''information_schema'') AND n.nspname NOT LIKE ''pg\\_%'''
\set not_extension 'NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.objid = o.oid AND d.deptype = ''e'')'
\echo '-- schemas'
SELECT format('ALTER SCHEMA %I OWNER TO %I', n.nspname, :'role')
FROM pg_namespace n
WHERE :user_schema
  AND n.nspowner <> :'role'::regrole
  AND pg_get_userbyid(n.nspowner) <> 'pg_database_owner'   -- PG15+ default for public: already the app
\gexec

\echo '-- tables, views, sequences (tables first: they carry their owned sequences)'
SELECT format('ALTER %s %I.%I OWNER TO %I',
              CASE o.relkind WHEN 'v' THEN 'VIEW' WHEN 'm' THEN 'MATERIALIZED VIEW'
                             WHEN 'S' THEN 'SEQUENCE' WHEN 'f' THEN 'FOREIGN TABLE' ELSE 'TABLE' END,
              n.nspname, o.relname, :'role')
FROM pg_class o JOIN pg_namespace n ON n.oid = o.relnamespace
WHERE :user_schema AND :not_extension
  AND o.relkind IN ('r', 'p', 'v', 'm', 'S', 'f')
  AND o.relowner <> :'role'::regrole
ORDER BY o.relkind = 'S'
\gexec

\echo '-- enum types and domains'
SELECT format('ALTER %s %I.%I OWNER TO %I',
              CASE o.typtype WHEN 'd' THEN 'DOMAIN' ELSE 'TYPE' END, n.nspname, o.typname, :'role')
FROM pg_type o JOIN pg_namespace n ON n.oid = o.typnamespace
WHERE :user_schema AND :not_extension
  AND o.typtype IN ('e', 'd')
  AND o.typowner <> :'role'::regrole
\gexec

\echo '-- functions / procedures'
SELECT format('ALTER ROUTINE %s OWNER TO %I', o.oid::regprocedure, :'role')
FROM pg_proc o JOIN pg_namespace n ON n.oid = o.pronamespace
WHERE :user_schema AND :not_extension
  AND o.proowner <> :'role'::regrole
\gexec

\echo '-- remaining relations NOT owned by the app role (should be empty):'
SELECT n.nspname AS schema, o.relname AS object, pg_get_userbyid(o.relowner) AS owner
FROM pg_class o JOIN pg_namespace n ON n.oid = o.relnamespace
WHERE :user_schema AND o.relkind IN ('r', 'p', 'v', 'm', 'S', 'f')
  AND o.relowner <> :'role'::regrole;
EOSQL
