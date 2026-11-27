#!/usr/bin/env bash
# Run every local test layer, then merge the Allure report. Exits non-zero when any layer fails.
# The mobile layer runs only when an Android emulator is connected (CI runs it on an emulator).
set -uo pipefail
cd "$(dirname "$0")/.."

rm -rf reports/allure-results reports/junit reports/logs reports/gatling reports/llm-eval reports/playwright-output
mkdir -p reports/logs

scripts/dev-up.sh > reports/logs/dev-up.log 2>&1 || { echo "dev-up failed, see reports/logs/dev-up.log"; exit 1; }

failed=()
suites=(sut-unit api web perf llm-eval)
if command -v adb >/dev/null 2>&1 && adb devices | grep -q "device$"; then suites+=(mobile); else echo "skip mobile: no Android emulator connected"; fi

for suite in "${suites[@]}"; do
  echo "=== $suite ==="
  if scripts/run-suite.sh "$suite" local > "reports/logs/$suite.log" 2>&1; then
    echo "PASS $suite"
  else
    echo "FAIL $suite (reports/logs/$suite.log)"
    failed+=("$suite")
  fi
done

scripts/report.sh local > reports/logs/report.log 2>&1 || echo "report generation failed, see reports/logs/report.log"

if [ ${#failed[@]} -gt 0 ]; then
  echo "failed suites: ${failed[*]}"
  exit 1
fi
echo "all suites passed"
