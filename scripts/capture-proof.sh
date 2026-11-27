#!/usr/bin/env bash
# Capture proof for a phase.  Usage: scripts/capture-proof.sh phase1|phase2
# phase1: run scripts/test-all.sh first (local stack up, reports in ./reports). Needs PAGES_URL and CI_RUN_URL.
# phase2: run scripts/deploy.sh first (cloud stack up, .local/cloud.env present).
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/aws-env.sh
phase="${1:?usage: capture-proof.sh phase1|phase2}"

copy_tree() { rm -rf "$2" && mkdir -p "$(dirname "$2")" && cp -r "$1" "$2"; }

if [ "$phase" = "phase1" ]; then
  dir=proof/phase1-local
  mkdir -p "$dir/tests" "$dir/logs" "$dir/screenshots"
  copy_tree reports/allure-report "$dir/tests/allure-report"
  copy_tree reports/gatling "$dir/tests/gatling"
  copy_tree reports/llm-eval "$dir/tests/llm-eval"
  copy_tree reports/junit "$dir/tests/junit"
  cp reports/logs/wrk.log "$dir/logs/wrk-smoke.log" 2>/dev/null || true
  cp reports/logs/gatling.log "$dir/logs/gatling-run.log" 2>/dev/null || true
  docker compose logs --no-color 2>&1 | redact > "$dir/logs/compose-services.log"
  (cd mcp/qa-mcp-server && node src/ci-client.ts seed && node src/ci-client.ts summary) 2>&1 | redact > "$dir/logs/mcp-ci-client.log"

  # Flip the seeded bug, show that API and web suites catch it, then restore.
  rm -rf reports/allure-results/api reports/allure-results/web reports/playwright-html
  SUT_BUG_ROUNDING=1 docker compose up -d --wait transfers
  scripts/run-suite.sh api local > "$dir/logs/bug-rounding-api.log" 2>&1 || true
  scripts/run-suite.sh web local > "$dir/logs/bug-rounding-web.log" 2>&1 || true
  REPORT_OUT=reports/allure-report-bug scripts/report.sh local > /dev/null
  docker compose up -d --wait transfers

  PAGES_URL="${PAGES_URL:?set PAGES_URL}" CI_RUN_URL="${CI_RUN_URL:?set CI_RUN_URL}" node scripts/capture-screenshots.mjs phase1
else
  dir=proof/phase2-cloud
  mkdir -p "$dir/tests" "$dir/logs" "$dir/screenshots"
  set -a && source .local/cloud.env && set +a
  copy_tree reports/allure-report-cloud "$dir/tests/allure-report-cloud"
  copy_tree reports/llm-eval-bedrock "$dir/tests/llm-eval-bedrock"
  copy_tree reports/junit "$dir/tests/junit"
  cp reports/logs/cloud-*.log "$dir/logs/" 2>/dev/null || true
  python scripts/drift-compare.py > "$dir/logs/drift-mock-vs-bedrock.json"

  {
    echo "# Deployed AWS resources ($(date -u +%Y-%m-%dT%H:%M:%SZ))"
    terraform -chdir=infra output
    aws ecs describe-services --cluster bank-qa --services accounts transfers chat web \
      --query 'services[].{service:serviceName,status:status,running:runningCount,desired:desiredCount}' --output table
    aws elbv2 describe-load-balancers --query 'LoadBalancers[?starts_with(LoadBalancerName, `bank-qa`)].{name:LoadBalancerName,dns:DNSName,state:State.Code}' --output table
    aws rds describe-db-instances --query 'DBInstances[].{id:DBInstanceIdentifier,class:DBInstanceClass,engine:Engine,status:DBInstanceStatus,public:PubliclyAccessible}' --output table
    aws secretsmanager list-secrets --query 'SecretList[?starts_with(Name, `bank-qa/`)].Name' --output table
    aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=bank-qa-automation --query 'ResourceTagMappingList[].ResourceARN' --output text | tr '\t' '\n'
  } 2>&1 | redact > "$dir/resources.txt"

  for service in accounts transfers chat; do
    aws logs tail "/ecs/bank-qa/$service" --since 2h 2>&1 | redact | tail -40 > "$dir/logs/cloudwatch-$service.log" || true
  done

  alb_suffix=$(aws elbv2 describe-load-balancers --names bank-qa --query 'LoadBalancers[0].LoadBalancerArn' --output text | sed -E 's#.*loadbalancer/##')
  aws cloudwatch get-metric-widget-image --output text --query MetricWidget \
    --metric-widget "{\"metrics\":[[\"AWS/ApplicationELB\",\"RequestCount\",\"LoadBalancer\",\"$alb_suffix\",{\"stat\":\"Sum\"}]],\"period\":60,\"title\":\"ALB request count\",\"width\":900,\"height\":300,\"start\":\"-PT2H\",\"region\":\"$AWS_REGION\"}" \
    | base64 -d > "$dir/screenshots/04-cloudwatch-alb-requests.png" || true

  node scripts/capture-screenshots.mjs phase2
fi
echo "proof captured for $phase"
