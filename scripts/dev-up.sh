#!/usr/bin/env bash
# Start the whole SUT locally with Docker Compose and load demo data.
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose up -d --build --wait
scripts/seed.sh
echo "SUT is up: web http://localhost:8080  accounts :3001  transfers :3002  chat :3003"
