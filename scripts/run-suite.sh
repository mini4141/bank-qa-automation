#!/usr/bin/env bash
# Run one test suite.  Usage: scripts/run-suite.sh <sut-unit|api|web|perf|llm-eval|mobile> [local|cloud]
# Cloud runs read endpoint URLs from .local/cloud.env (written by scripts/deploy.sh).
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/tools/apache-maven-3.9.9/bin:$PATH"
unset MSYS_NO_PATHCONV  # set by aws-env.sh; breaks the Windows mvn launcher

suite="${1:?usage: run-suite.sh <suite> [local|cloud]}"
env_name="${2:-local}"
mkdir -p reports/junit reports/logs

if [ "$env_name" = "cloud" ]; then
  # shellcheck disable=SC1091
  set -a && source .local/cloud.env && set +a
  export SUT_RUNTIME=none
  api_tags='not @needs-runtime-control'
else
  api_tags="${API_TAGS:-}"
fi

case "$suite" in
  sut-unit)
    for svc in accounts-service transfers-service; do
      (cd "sut/$svc" && pnpm lint && pnpm test)
    done
    (cd sut/inquiry-chat && uv run ruff check . && uv run pytest -q --junitxml=../../reports/junit/chat-unit.xml)
    (cd mcp/qa-mcp-server && pnpm lint && pnpm test)
    ;;
  api)
    tag_args=()
    [ -n "$api_tags" ] && tag_args=("-Dcucumber.filter.tags=$api_tags")
    (cd tests/api && mvn -B -q test "${tag_args[@]}") && status=0 || status=$?
    cp tests/api/target/surefire-reports/TEST-*.xml reports/junit/api.xml 2>/dev/null || true
    exit $status
    ;;
  web)
    (cd tests/web && pnpm exec bddgen && pnpm exec playwright test)
    ;;
  perf)
    export USERS="${USERS:-50}" RAMP_SECONDS="${RAMP_SECONDS:-60}"
    if [ "$env_name" = "cloud" ]; then USERS=20 RAMP_SECONDS=30; fi
    set +e
    (cd tests/perf && mvn -B gatling:test) 2>&1 | tee reports/logs/gatling.log
    gatling_status=${PIPESTATUS[0]}
    set -e
    python scripts/gatling-to-allure.py reports/logs/gatling.log reports/allure-results/perf
    tests/perf/wrk/smoke.sh | tee reports/logs/wrk.log
    exit "$gatling_status"
    ;;
  llm-eval)
    provider=mock
    [ "$env_name" = "cloud" ] && provider=bedrock
    out="reports/llm-eval"
    [ "$provider" = "bedrock" ] && out="reports/llm-eval-bedrock"
    (cd llm-eval && uv run pytest -q --provider "$provider" --report-dir "../$out" ${EVAL_ARGS:-})
    ;;
  mobile)
    (cd tests/mobile && pnpm test)
    ;;
  *)
    echo "unknown suite: $suite" >&2
    exit 2
    ;;
esac
