#!/usr/bin/env bash
# Rotate the LLM key / DB credential. Never prints secret values.
#   scripts/rotate-secret.sh local   -> new random mock LLM key written to .env (gitignored)
#   scripts/rotate-secret.sh cloud   -> new database password in AWS Secrets Manager (bank-qa/database-url)
set -euo pipefail
cd "$(dirname "$0")/.."
target="${1:?usage: rotate-secret.sh local|cloud}"
new=$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)

if [ "$target" = "local" ]; then
  touch .env
  grep -v '^LLM_API_KEY=' .env > .env.tmp || true
  echo "LLM_API_KEY=$new" >> .env.tmp
  mv .env.tmp .env
  echo "rotated LLM_API_KEY in .env; restart with: docker compose up -d chat"
else
  # shellcheck disable=SC1091
  source scripts/aws-env.sh
  current=$(aws secretsmanager get-secret-value --secret-id bank-qa/database-url --query SecretString --output text)
  updated=$(echo "$current" | sed -E "s#(postgres://bank:)[^@]+@#\1$new@#")
  aws rds modify-db-instance --db-instance-identifier bank-qa --master-user-password "$new" --apply-immediately > /dev/null
  aws secretsmanager put-secret-value --secret-id bank-qa/database-url --secret-string "$updated" > /dev/null
  for service in accounts transfers; do
    aws ecs update-service --cluster bank-qa --service "$service" --force-new-deployment > /dev/null
  done
  echo "rotated the database credential in Secrets Manager and redeployed accounts and transfers"
fi
