#!/usr/bin/env bash
# Run the cloud-capable suites against the deployed stack and merge the cloud Allure report.
# Records the Bedrock baseline on the first run; later runs are checked for drift against it.
set -uo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/aws-env.sh

rm -rf reports/allure-results reports/junit reports/llm-eval-bedrock reports/gatling
mkdir -p reports/logs
failed=0
for suite in api web perf; do
  scripts/run-suite.sh "$suite" cloud > "reports/logs/cloud-$suite.log" 2>&1 && echo "PASS $suite" || { echo "FAIL $suite"; failed=1; }
done
extra=""
[ -f llm-eval/baselines/bedrock.json ] || extra="--record-baseline"
EVAL_ARGS="$extra" scripts/run-suite.sh llm-eval cloud > reports/logs/cloud-llm-eval.log 2>&1 && echo "PASS llm-eval" || { echo "FAIL llm-eval"; failed=1; }
scripts/report.sh cloud > reports/logs/cloud-report.log 2>&1
exit $failed
