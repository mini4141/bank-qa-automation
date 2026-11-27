#!/usr/bin/env bash
# Load demo data through the public APIs. Safe to run repeatedly.
set -euo pipefail
ACCOUNTS_URL="${ACCOUNTS_URL:-http://localhost:3001}"
TRANSFERS_URL="${TRANSFERS_URL:-http://localhost:3002}"

post() { curl -fsS -X POST -H 'content-type: application/json' "$@"; }
field() { sed -E "s/.*\"$1\":\"?([^\",}]*)\"?.*/\1/"; }

alice=$(post -d '{"name":"Alice Demo","type":"checking"}' "$ACCOUNTS_URL/accounts" | field id)
bob=$(post -d '{"name":"Bob Demo","type":"savings"}' "$ACCOUNTS_URL/accounts" | field id)
post -d '{"amountMinor":500000}' "$ACCOUNTS_URL/accounts/$alice/deposits" > /dev/null
post -H 'Idempotency-Key: seed-demo-1' -d "{\"fromId\":\"$alice\",\"toId\":\"$bob\",\"amountMinor\":2500}" "$TRANSFERS_URL/transfers" > /dev/null
echo "seeded demo accounts: alice=$alice bob=$bob"
