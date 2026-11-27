#!/usr/bin/env bash
# Tear the AWS stack down. Idempotent: safe to run repeatedly, even after a partial deploy.
set -uo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/aws-env.sh

# Things that can block terraform destroy: running services and images in registries.
if aws ecs describe-clusters --clusters bank-qa --query 'clusters[?status==`ACTIVE`].clusterName' --output text | grep -q bank-qa; then
  for service in $(aws ecs list-services --cluster bank-qa --query 'serviceArns[]' --output text); do
    aws ecs update-service --cluster bank-qa --service "$service" --desired-count 0 > /dev/null || true
  done
fi
for repo in accounts transfers chat web; do
  ids=$(aws ecr list-images --repository-name "bank-qa/$repo" --query 'imageIds[]' --output json 2> /dev/null || echo '[]')
  if [ "$ids" != "[]" ] && [ -n "$ids" ]; then
    aws ecr batch-delete-image --repository-name "bank-qa/$repo" --image-ids "$ids" > /dev/null || true
  fi
done

terraform -chdir=infra init -input=false > /dev/null
terraform -chdir=infra destroy -input=false -auto-approve || terraform -chdir=infra destroy -input=false -auto-approve
rm -f .local/cloud.env
echo "destroy finished"
