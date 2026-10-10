#!/usr/bin/env bash
# Spins up a throwaway Postgres, applies the Supabase stub + all migrations + seed, runs behaviour tests.
# Requires Postgres 15+ binaries on PATH (CI uses the postgres service image; locally: brew install postgresql@17).
set -euo pipefail
export LC_ALL="${LC_ALL:-C}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -n "${DATABASE_URL:-}" ]]; then
  DB="$DATABASE_URL"
else
  PGBIN="${PGBIN:-$(brew --prefix postgresql@17 2>/dev/null)/bin}"
  export PATH="$PGBIN:$PATH"
  DATA="$(mktemp -d)"; PORT=54329
  initdb -D "$DATA" -U postgres -A trust >/dev/null
  pg_ctl -D "$DATA" -w -o "-p $PORT -c listen_addresses=localhost -c unix_socket_directories=''" -l "$DATA/log" start >/dev/null
  trap 'pg_ctl -D "$DATA" stop -m immediate >/dev/null; rm -rf "$DATA"' EXIT
  DB="postgresql://postgres@localhost:$PORT/postgres"
fi

run() { psql "$DB" -X -q -v ON_ERROR_STOP=1 "$@"; }
run -f "$ROOT/supabase/tests/supabase_stub.sql"
for f in "$ROOT"/supabase/migrations/*.sql; do run -f "$f"; done
run -f "$ROOT/supabase/seed.sql"
run -f "$ROOT/supabase/tests/behaviour_test.sql" 2>&1 | sed -E 's/^psql:.*NOTICE:  /  /'
