#!/usr/bin/env bash
# Runs inside the Android emulator job: start Appium 2, wait for it, run the WebdriverIO + Cucumber suite.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p reports/logs

appium --allow-insecure=uiautomator2:chromedriver_autodownload > reports/logs/appium.log 2>&1 &
for _ in $(seq 1 30); do
  curl -fsS http://127.0.0.1:4723/status > /dev/null && break
  sleep 2
done

export MOBILE_WEB_URL=http://10.0.2.2:8080
cd tests/mobile
pnpm test
