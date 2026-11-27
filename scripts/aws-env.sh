#!/usr/bin/env bash
# Sourced by the AWS scripts: fixed profile and region (see CLAUDE.md section 4).
export AWS_PROFILE=bank-qa-automation-deployer
export AWS_REGION=ap-southeast-2
export AWS_DEFAULT_REGION=ap-southeast-2
export AWS_PAGER=""
export MSYS_NO_PATHCONV=1

# Redact 12-digit account ids, access keys and bearer tokens from anything saved as proof.
redact() {
  sed -E 's/[0-9]{12}/<ACCOUNT_ID>/g; s/(AKIA|ASIA)[A-Z0-9]{16}/<ACCESS_KEY>/g; s/(Bearer )[A-Za-z0-9._-]+/\1<TOKEN>/g'
}
