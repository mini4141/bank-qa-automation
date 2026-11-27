#!/usr/bin/env bash
# wrk quick smoke on GET /accounts/:id. Uses a native wrk when present, otherwise the wrk Docker image.
set -euo pipefail
cd "$(dirname "$0")/../../.."
ACCOUNTS_URL="${ACCOUNTS_URL:-http://localhost:3001}"
DURATION="${WRK_DURATION:-10s}"
OUT="${WRK_OUT:-reports/wrk/smoke.txt}"
mkdir -p "$(dirname "$OUT")"

id=$(curl -fsS -X POST -H 'content-type: application/json' -d '{"name":"Wrk Smoke","type":"checking"}' "$ACCOUNTS_URL/accounts" \
  | sed -E 's/.*"id":"([^"]+)".*/\1/')

if command -v wrk >/dev/null 2>&1; then
  wrk -t2 -c20 -d"$DURATION" --latency "$ACCOUNTS_URL/accounts/$id" | tee "$OUT"
else
  target="${ACCOUNTS_URL/localhost/host.docker.internal}"
  MSYS_NO_PATHCONV=1 docker run --rm --add-host=host.docker.internal:host-gateway williamyeh/wrk:4.0.2 \
    -t2 -c20 -d"$DURATION" --latency "$target/accounts/$id" | tee "$OUT"
fi
