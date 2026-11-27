#!/usr/bin/env bash
# Regenerate the Linux visual baselines (used by CI) inside the official Playwright image.
# Needs the SUT running locally (scripts/dev-up.sh).
set -euo pipefail
cd "$(dirname "$0")/.."
MSYS_NO_PATHCONV=1 docker run --rm --add-host=host.docker.internal:host-gateway \
  -e WEB_URL=http://host.docker.internal:8080 -e ACCOUNTS_URL=http://host.docker.internal:3001 \
  -v "$PWD:/repo" mcr.microsoft.com/playwright:v1.57.0-noble bash -c '
    set -e
    apt-get update -qq && apt-get install -y -qq fonts-dejavu-core
    mkdir -p /work && cd /repo/tests/web
    tar --exclude=node_modules --exclude=.features-gen -cf - . | tar -xf - -C /work
    cd /work && npm install -g pnpm@12.3.4 >/dev/null
    pnpm install --frozen-lockfile >/dev/null
    pnpm exec bddgen
    pnpm exec playwright test --update-snapshots=all || true
    cp snapshots/*-linux.png /repo/tests/web/snapshots/
  '
