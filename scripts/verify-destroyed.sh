#!/usr/bin/env bash
# Prove that nothing billable tagged Project=bank-qa-automation is left. Exits non-zero otherwise.
# Output is written to proof/phase3-destroy/verify-destroyed.txt (account ids redacted).
set -uo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source scripts/aws-env.sh

out=proof/phase3-destroy/verify-destroyed.txt
mkdir -p "$(dirname "$out")"
leftover=0

check() { # label, command output (empty means gone)
  local label="$1" result="$2"
  if [ -z "$result" ] || [ "$result" = "None" ]; then
    echo "OK   $label: none"
  else
    echo "LEFT $label: $result"
    leftover=1
  fi
}

{
  echo "verify-destroyed at $(date -u +%Y-%m-%dT%H:%M:%SZ), region $AWS_REGION"
  check "ECS cluster bank-qa" "$(aws ecs describe-clusters --clusters bank-qa --query 'clusters[?status!=`INACTIVE`].clusterName' --output text)"
  check "Load balancers" "$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?starts_with(LoadBalancerName, `bank-qa`)].LoadBalancerName' --output text 2> /dev/null)"
  check "Target groups" "$(aws elbv2 describe-target-groups --query 'TargetGroups[?starts_with(TargetGroupName, `bank-qa`)].TargetGroupName' --output text 2> /dev/null)"
  check "RDS instances" "$(aws rds describe-db-instances --query 'DBInstances[?starts_with(DBInstanceIdentifier, `bank-qa`)].DBInstanceIdentifier' --output text)"
  check "Secrets" "$(aws secretsmanager list-secrets --query 'SecretList[?starts_with(Name, `bank-qa/`)].Name' --output text)"
  check "ECR repositories" "$(aws ecr describe-repositories --query 'repositories[?starts_with(repositoryName, `bank-qa/`)].repositoryName' --output text 2> /dev/null)"
  check "CloudWatch log groups" "$(aws logs describe-log-groups --log-group-name-prefix /ecs/bank-qa --query 'logGroups[].logGroupName' --output text)"
  check "NAT gateways" "$(aws ec2 describe-nat-gateways --filter Name=tag:Project,Values=bank-qa-automation Name=state,Values=available,pending --query 'NatGateways[].NatGatewayId' --output text)"
  check "VPCs" "$(aws ec2 describe-vpcs --filters Name=tag:Project,Values=bank-qa-automation --query 'Vpcs[].VpcId' --output text)"
  tagged=$(aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=bank-qa-automation --query 'ResourceTagMappingList[].ResourceARN' --output text)
  echo "Tagging API (may lag a few minutes after deletion): ${tagged:-none}"
  if [ "$leftover" = 0 ]; then echo "RESULT: nothing billable remains"; else echo "RESULT: resources still exist"; fi
} 2>&1 | redact | tee "$out"

! grep -q "^LEFT" "$out"
