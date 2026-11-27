# QA report: Phase 2 (AWS)

Environment: ECS Fargate (accounts, transfers, chat, web) behind one ALB, RDS PostgreSQL `db.t4g.micro`, Amazon Bedrock (Nova Lite for chat, Titan Text Embeddings v2), region `ap-southeast-2`. Tests ran from the dev PC against the ALB URL. The stack lived about 30 minutes.

## Results
| Suite | Result | Notes |
|---|---|---|
| API (13 scenarios, resilience excluded) | pass | the `@needs-runtime-control` scenario needs Compose or kind and is skipped in the cloud |
| Web (5 scenarios x Chromium, WebKit) | pass | against the ALB |
| Performance | pass | 20 users over 30 s; wrk smoke about 45 requests/s with p50 about 390 ms, dominated by the network path from the dev PC |
| LLM eval on Bedrock | pass | all six quality metrics 1.00; latency p95 about 1.0 s; baseline `llm-eval/baselines/bedrock.json` recorded on the first run, the rerun was checked for drift against it (delta 0) |

## Mock versus Bedrock
`proof/phase2-cloud/logs/drift-mock-vs-bedrock.json` compares the two baselines. All six metrics are 1.00 for both, so the delta is zero. The comparison still earned its place: the real model exposed DEF-003, which the mock cannot produce.

## Defects found in the cloud
| Id | Summary | Status |
|---|---|---|
| DEF-003 | A refusal carried a citation | fixed |
| (deployment) | RDS Postgres 16 rejects non-TLS connections, so the first tasks crash-looped and the ALB returned 503 | fixed with `sslmode=no-verify` (see `docs/DECISIONS.md`) |
| (tooling) | `MSYS_NO_PATHCONV` exported by the AWS helper broke the Windows Maven launcher | fixed in `scripts/run-suite.sh` |

## Cost and cleanup
About 30 minutes of one ALB, four 0.25 vCPU Fargate tasks and one `db.t4g.micro`, plus a few hundred Bedrock calls on the cheapest model: well under 1 USD. `scripts/destroy.sh` removed 50 resources and `scripts/verify-destroyed.sh` found nothing billable left (`proof/phase3-destroy/verify-destroyed.txt`).
