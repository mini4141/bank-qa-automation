#!/usr/bin/env bash
# Stop the local SUT and remove its volumes.
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose down -v --remove-orphans
