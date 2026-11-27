#!/usr/bin/env bash
# Deploy the SUT to AWS (ECS Fargate, ALB, RDS, Bedrock) and run the cloud tests from this PC.
# Usage: scripts/deploy.sh [--no-tests]      Tear down afterwards with scripts/destroy.sh
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/aws-env.sh

aws sts get-caller-identity --query Arn --output text | redact
account=$(aws sts get-caller-identity --query Account --output text)
registry="$account.dkr.ecr.$AWS_REGION.amazonaws.com"
tf_vars=()
[ -n "${BEDROCK_MODEL_ID:-}" ] && tf_vars+=(-var "bedrock_model_id=$BEDROCK_MODEL_ID")

terraform -chdir=infra init -input=false
# 1. registries first, so images exist before ECS starts tasks
terraform -chdir=infra apply -input=false -auto-approve -target=aws_ecr_repository.svc "${tf_vars[@]}"

# 2. build and push images
aws ecr get-login-password | docker login --username AWS --password-stdin "$registry" > /dev/null
build_push() { # name, dockerfile, context
  docker build -q -t "$registry/bank-qa/$1:latest" -f "$2" "$3"
  docker push -q "$registry/bank-qa/$1:latest"
}
build_push accounts sut/accounts-service/Dockerfile sut/accounts-service
build_push transfers sut/transfers-service/Dockerfile sut/transfers-service
build_push chat sut/inquiry-chat/Dockerfile sut
build_push web sut/web/Dockerfile sut/web

# 3. everything else
terraform -chdir=infra apply -input=false -auto-approve "${tf_vars[@]}"
alb=$(terraform -chdir=infra output -raw alb_url)
aws ecs wait services-stable --cluster bank-qa --services accounts transfers chat web

mkdir -p .local
cat > .local/cloud.env <<EOF
WEB_URL=$alb
ACCOUNTS_URL=$alb/api/accounts
TRANSFERS_URL=$alb/api/transfers
CHAT_URL=$alb/api/chat
EVAL_PROVIDER=bedrock
BEDROCK_MODEL_ID=${BEDROCK_MODEL_ID:-$(terraform -chdir=infra console <<< var.bedrock_model_id | tr -d '"')}
AWS_PROFILE=$AWS_PROFILE
AWS_REGION=$AWS_REGION
EOF

# wait until the ALB routes to healthy targets
for _ in $(seq 1 60); do
  curl -fsS "$alb/api/accounts/healthz" > /dev/null && curl -fsS "$alb/api/chat/healthz" > /dev/null && break
  sleep 5
done

ACCOUNTS_URL="$alb/api/accounts" TRANSFERS_URL="$alb/api/transfers" scripts/seed.sh

[ "${1:-}" = "--no-tests" ] && exit 0

rm -rf reports/allure-results
failed=0
for suite in api web perf; do
  scripts/run-suite.sh "$suite" cloud > "reports/logs/cloud-$suite.log" 2>&1 || { echo "FAIL $suite"; failed=1; }
done
EVAL_ARGS="--record-baseline" scripts/run-suite.sh llm-eval cloud > reports/logs/cloud-llm-eval.log 2>&1 || { echo "FAIL llm-eval"; failed=1; }
scripts/report.sh cloud
exit $failed
