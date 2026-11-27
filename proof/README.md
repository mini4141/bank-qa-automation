# Proof index

Every artifact on one line, with what it proves. Screenshots are produced by `scripts/capture-proof.sh` (headless Playwright), never by hand.

Live report: https://mini4141.github.io/bank-qa-automation/ . CI run with all jobs green: https://github.com/mini4141/bank-qa-automation/actions/runs/45955987020

## Phase 1: local (`phase1-local/`)
| Artifact | Proves |
|---|---|
| `screenshots/01-allure-overview.png` | merged Allure report, all suites green |
| `screenshots/02-allure-api-feature.png` | Cucumber API features and scenarios in Allure |
| `screenshots/03-playwright-trace.png` | Playwright trace of a failing run (seeded bug: balance 89.74, fee 0.16) |
| `screenshots/04-gatling-report.png` | Gatling HTML report with passed assertions |
| `screenshots/05-llm-eval-summary.png` | LLM metrics against thresholds |
| `screenshots/06-bug-caught-rounding.png` | API and web scenarios failing when `SUT_BUG_ROUNDING=1` |
| `screenshots/07-github-pages-report.png` | the report served from GitHub Pages |
| `screenshots/08-ci-matrix.png` | GitHub Actions run: unit, api, web, perf, llm-eval, mobile, k8s, report |
| `tests/allure-report/` | merged Allure HTML report (open `index.html` through a web server) |
| `tests/gatling/` | Gatling reports; `tests/junit/` JUnit XML for api, web and unit tests |
| `tests/llm-eval/report.html`, `report.json` | eval summary and per-item details |
| `tests/mobile-ci/` | mobile suite artifacts from the CI emulator job: Appium log and device screenshots (no emulator on the dev PC) |
| `logs/mcp-ci-client.log` | local MCP client calling `seed_test_data`, `get_report_summary`, `list_flaky_tests` over stdio |
| `logs/mcp-ci-client-summary-ci.log`, `mcp-ci-client-seed-ci.log` | the same MCP calls made from the CI jobs |
| `logs/k8s-api-job.log` | SUT deployed to kind and the API suite passing against it, including the service-down scenario |
| `logs/bug-rounding-api.log`, `bug-rounding-web.log` | failures caused by the seeded rounding bug |
| `logs/compose-services.log` | structured JSON service logs from Docker Compose |
| `logs/wrk-smoke.log`, `gatling-run.log` | wrk and Gatling console output |

Defect report for the seeded bug: `docs/defects/DEF-001-fee-rounding.md`. Results summary: `docs/qa-report-phase1.md`.

## Phase 2: cloud (`phase2-cloud/`)
| Artifact | Proves |
|---|---|
| `resources.txt` | deployed resources: ALB, four ECS services (1/1 running), RDS instance, secrets, tagged ARNs |
| `screenshots/01-cloud-allure.png` | Allure report of the suites run against the ALB |
| `screenshots/02-cloud-web-app.png` | the web app on AWS: account opened, assistant answers from Bedrock with a source link |
| `screenshots/03-bedrock-eval.png` | LLM eval on Bedrock, all metrics against thresholds |
| `screenshots/04-cloudwatch-alb-requests.png` | CloudWatch metric image: ALB request count while tests ran |
| `tests/allure-report-cloud/` | cloud Allure report (serve over HTTP) |
| `tests/llm-eval-bedrock/` | Bedrock eval report (`report.html`, `report.json`) |
| `tests/junit/` | JUnit XML of the cloud API run |
| `logs/drift-mock-vs-bedrock.json` | mock baseline versus Bedrock baseline, metric by metric |
| `logs/cloud-*.log` | console output of each cloud suite |
| `logs/cloudwatch-*.log` | CloudWatch Logs of the services (structured JSON, account ids redacted) |

Account ids, tokens and keys are redacted in all logs. Results summary: `docs/qa-report-phase2.md`; defect found in the cloud: `docs/defects/DEF-003-refusal-with-citation.md`.

## Phase 3: destroy (`phase3-destroy/`)
| Artifact | Proves |
|---|---|
| `verify-destroyed.txt` | no ECS cluster, load balancer, target group, RDS instance, secret, ECR repository, log group, NAT gateway or VPC remains. The tagging API still lists a few inactive ECS task definitions and one subnet for a short while after deletion; the direct describe calls above it are authoritative |
