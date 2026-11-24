# CLAUDE.md — bank-qa-automation

These are the engineering rules for Claude Code on this repository. You work **fully autonomously**. Don't stop to ask the user questions. When something is ambiguous, pick the simplest option that keeps every stack item in §2 covered. Record it in `docs/DECISIONS.md` (one line: date, decision, reason) and keep going. Read `SPECS.md` end to end before writing any code. It is the source of truth for features, architecture and proof.

## 1. Project at a glance

| | |
|---|---|
| Project | Bank QA Automation: full-stack test automation (API, web, mobile, performance, LLM validation) for a microservice banking app |
| Repo | public GitHub repo `bank-qa-automation`. `origin` is already configured and the default branch is `main` |
| Target role | Full-Stack QA Engineer, digital banking (test automation, CI/CD, AI system validation) |
| Pitch | A small microservice banking app with an LLM 'inquiry chat' is the system under test. The real deliverable is the quality platform around it: BDD suites for API (Rest-Assured), web (Playwright) and mobile (Appium), Gatling performance tests, an LLM/RAG evaluation harness that catches hallucinations, bias and drift, an MCP server that exposes test tools to AI assistants, and CI that publishes one Allure report. |
| Priority | **Breadth of the tech stack beats depth of business logic.** Every technology in §2 must appear in running code and be visible in the proof. Full validation, edge cases and complete domain rules are out of scope. |

## 2. Mandatory tech stack

| Area | Technology |
|---|---|
| System under test | `sut/accounts-service` + `sut/transfers-service` (Node 24 + TypeScript + Fastify, PostgreSQL), `sut/web` (React + Vite, mobile-responsive), `sut/inquiry-chat` (Python FastAPI RAG service over bundled FAQ docs) |
| API tests | Java 21 + Maven, **Cucumber JVM** + **Rest-Assured** + JUnit 5 platform |
| Web tests | **Playwright** (TypeScript) + `playwright-bdd` (**Cucumber**/Gherkin) |
| Mobile tests | **Appium 2** (UiAutomator2) + WebdriverIO + Cucumber, testing the web app in Chrome on an Android emulator (mobile web) |
| Performance | **Gatling** (Java DSL) load profile + `wrk` quick smoke |
| LLM / AI validation | Python 3.12 + pytest harness: RAG retrieval hit@k, faithfulness/hallucination check (LLM-as-judge + citation grounding), bias (paired-prompt parity), drift (golden-set baseline vs current), robustness (typos/paraphrase), prompt-injection resistance |
| LLM provider | The official `openai` Python SDK against an **OpenAI-compatible endpoint**: a local mock server (deterministic) or **Amazon Bedrock** in the cloud (its OpenAI-compatible Chat Completions endpoint if available in-region, otherwise boto3 Converse behind the same interface); embeddings via **Bedrock Titan Text Embeddings v2** |
| Key management | LLM keys and credentials in **AWS Secrets Manager** (cloud) / `.env` (local, gitignored), a rotation script, and never logged |
| MCP | `qa-mcp-server` (TypeScript, `@modelcontextprotocol/sdk`) exposing `seed_test_data`, `run_suite`, `get_report_summary`, `list_flaky_tests`; called from CI through an MCP client step |
| CI/CD | **GitHub Actions** matrix (api, web, mobile on an emulator via `reactivecircus/android-emulator-runner`, perf smoke, llm-eval with mock), **Allure** results merged and published to **GitHub Pages** |
| Containers | Docker Compose for the SUT; a **kind** job in CI deploys the SUT to Kubernetes and runs the API suite against it (microservices testing) |
| AWS | ECS Fargate (SUT services), ALB, RDS PostgreSQL, Bedrock, Secrets Manager, CloudWatch |
| IaC | **Terraform** |

Don't swap an item for an alternative. If a library is unavailable or broken, use the closest equivalent and log the swap in `docs/DECISIONS.md`.

## 3. Environment

- The host is a **Windows 11 PC**. Claude Code's shell is Git Bash, and the container runtime is Docker Desktop (WSL2 backend). Write automation as POSIX `bash` scripts under `scripts/` and use forward-slash paths. Add a `.gitattributes` with `* text=auto eol=lf` so scripts keep LF line endings.
- Prerequisites: Java 21 + Maven, Node.js 24 + pnpm, Python 3.12 + uv, Docker Desktop, kind, Android SDK + emulator (optional locally; CI runs mobile), Appium 2 (`npm i -g appium` + `appium driver install uiautomator2`), Terraform, AWS CLI v2. If one is missing, install it with `winget` or the official installer and record the version in `docs/DECISIONS.md`.
- The `gh` CLI is logged in to the owner's GitHub account, and AWS CLI v2 is installed.
- Don't use Bitnami charts or images (their free catalogue has been retired). Use official upstream images and charts.

## 4. AWS account rules

- Profile: **`bank-qa-automation-deployer`**. Always pass it explicitly, either as `--profile bank-qa-automation-deployer` or by exporting `AWS_PROFILE=bank-qa-automation-deployer` inside the scripts. Never use the default profile or any other profile.
- Region: **`ap-southeast-2`** for everything except global services such as CloudFront and IAM.
- The profile has `PowerUserAccess` + `IAMFullAccess`. Start Phase 2 with `aws sts get-caller-identity --profile bank-qa-automation-deployer`. If that fails, stop and write the reason at the top of `PROGRESS.md`.
- Use AWS only. Where a requirement names Azure, GCP or another hyperscaler, use the AWS equivalent stated in `SPECS.md`.
- IaC: Terraform (`infra/`). Don't create resources by hand in the console: every cloud resource comes from code in `infra/`. Keep IaC state local and gitignored.
- Tag every resource with `Project=bank-qa-automation`, `Ephemeral=true`, `ManagedBy=<tool>` and `Owner=alvieirvansyah`.
- Deployment runs **from this PC via scripts** (`scripts/deploy.sh`, `scripts/destroy.sh`). GitHub Actions only builds and tests, and never holds AWS credentials. CI publishes the Allure report to GitHub Pages using the built-in `GITHUB_TOKEN` (enable Pages with the source set to 'GitHub Actions' via `gh api` in Phase 0).

## 5. Phases and gates

Work strictly in order. A phase is done only when its proof exists (§8) and its items are ticked in `PROGRESS.md`. Commit and push at the end of every phase.

1. **Phase 0, scaffold.** Set up the repo layout from `SPECS.md` §4. Create `README.md`, `PROGRESS.md` (copy every checklist item from `SPECS.md` §2 and §9–§11 into it), `docs/DECISIONS.md`, `.gitignore`, `.gitattributes`, `.env.example` and the CI workflow.
2. **Phase 1, local.** Build every feature in `SPECS.md` §5. Everything runs on this PC with Docker and local tooling, and makes **no AWS calls**: use the local stand-ins listed in `SPECS.md`. Run the full test suite, then capture proof into `proof/phase1-local/`. Phase 1 counts as "ready for next" only when `scripts/test-all.sh` is green, the CI run on `main` is green, and the proof index is complete.
3. **Phase 2, AWS showcase.** Deploy with `scripts/deploy.sh`, run the smoke/e2e tests against the cloud endpoints and capture proof into `proof/phase2-cloud/`. Keep the stack alive only as long as capturing takes, with a target of **under 2 hours**.
4. **Phase 3, destroy.** Right after capturing, run `scripts/destroy.sh` and then `scripts/verify-destroyed.sh`, and save the output to `proof/phase3-destroy/`. This phase is **mandatory even if Phase 2 partly failed**. Never end a session with cloud resources running.
5. **Phase 4, write-up.** Write `docs/PORTFOLIO.md`. It needs the problem, an architecture diagram (Mermaid), a stack → requirement table, the key screenshots (relative links into `proof/`), what was hard, the approximate AWS cost and how to reproduce. This file becomes a technical page on alvieirvansyah.com.

## 6. Engineering rules

- Keep it simple and conventional: idiomatic layout for each language, small modules, no premature abstraction, no dead code.
- Configure through environment variables, with a committed `.env.example`. Real `.env` files are gitignored.
- **Never commit secrets.** That includes credentials, IaC state, `.terraform/`, `cdk.out/`, kubeconfigs, private keys and certificates. Generate local dev keys and certs into a gitignored `.local/` folder.
- Every HTTP service exposes a health endpoint (`/healthz` or the framework idiom) and logs structured JSON to stdout.
- Pin versions: commit lockfiles and pin container images to at least a minor tag.
- Use one command for each job:
  - `scripts/dev-up.sh` starts everything locally and `scripts/dev-down.sh` stops it.
  - `scripts/seed.sh` loads demo data. Start-up may run it automatically so that demos never start empty.
  - `scripts/test-all.sh` runs every test layer.
  - `scripts/capture-proof.sh <phase>` captures the proof for a phase.
- Keep `README.md` current. It covers what the project is, the architecture diagram, a quickstart, deploy/destroy, a link to `proof/README.md` and `docs/PORTFOLIO.md`, and the CI badge.
- Don't put the hiring company's name anywhere in the repo. Describe the target role generically.
- `docs/AI_USAGE.md`: briefly note how AI coding tools were used and how their output was reviewed and tested.

## 7. Testing rules

- Tests are **shallow by design**: one happy-path test per feature or flow is enough. Don't write exhaustive validation or edge-case tests.
- Required layers: The test suites *are* the product: Cucumber API (≥ 6 scenarios), Playwright BDD web (≥ 5 scenarios), Appium mobile-web (≥ 3 scenarios), Gatling (1 simulation with assertions), LLM eval (≥ 1 test per category: retrieval, faithfulness, bias, drift, robustness, injection), plus a handful of SUT unit tests just so the SUT itself is credible.
- `scripts/test-all.sh` runs every local layer and exits non-zero on failure. CI runs every layer that doesn't need the cloud.
- Save test output as files (JUnit XML, an HTML report or a plain log) under the current phase's `proof/.../tests/`.

## 8. Proof rules

Proof is the deliverable. Use this folder layout:

```
proof/
  README.md                 # index: each artifact on one line, with what it proves
  phase1-local/
    screenshots/            # PNG, named NN-what-it-shows.png
    logs/                   # captured service logs and CLI output
    tests/                  # test reports
  phase2-cloud/
    screenshots/  logs/  tests/
    resources.txt           # deployed AWS resources (from IaC outputs / describe calls)
  phase3-destroy/
    verify-destroyed.txt
```

- Capture screenshots with a script (`scripts/capture-proof.sh`, driving Playwright headless), never by hand, so they can be reproduced. The screenshots listed in `SPECS.md` are the minimum.
- There is no AWS console login, so render AWS-side visuals from the CLI. For example, `aws cloudwatch get-metric-widget-image` renders a metrics graph as a PNG. Otherwise save CLI `describe`/`get` output as logs.
- Before saving logs or CLI output, redact 12-digit AWS account IDs (`sed -E 's/[0-9]{12}/<ACCOUNT_ID>/g'`), access keys, tokens, passwords and the deployer's public IP.
- Proof must show the system **working**, with real data flowing through it, and not just "deployed".

## 9. Cost and safety guardrails (AWS)

- Use the smallest viable sizes: Fargate 0.25–0.5 vCPU × 1 per SUT service, RDS `db.t4g.micro`, one ALB, Bedrock on-demand (cap the LLM eval at the golden set of about 30 prompts per run).
- **No NAT gateways.** Also no multi-AZ databases, provisioned IOPS, reserved capacity or Savings Plans, Route 53 domains, or Marketplace subscriptions.
- Databases: `deletion_protection = false`, skip the final snapshot and keep backup retention minimal. S3 buckets are force-destroyable and ECR repos force-deletable. CloudWatch log groups get 1-day retention and are created by IaC, so they get destroyed with it.
- Public app endpoints are fine for the showcase. Keep databases private: their security groups admit only the app tier. Don't open SSH or database ports to `0.0.0.0/0` and don't use SSH at all. Use SSM if you need a shell.
- Don't send real emails or SMS, and don't call paid third-party APIs. Anything external is mocked unless `SPECS.md` says otherwise.
- `scripts/destroy.sh` must be idempotent and safe to re-run. It first deletes anything that would block the IaC destroy: scale ECS services to 0, empty the ECR repos.
- `scripts/verify-destroyed.sh` lists anything still tagged `Project=bank-qa-automation` (`aws resourcegroupstaggingapi get-resources`) and runs the specific checks in `SPECS.md` §11. It exits non-zero if anything billable remains. The tagging API can show resources for a few minutes after deletion, so confirm each hit with a direct describe call before failing.

## 10. Git and CI

- Use Conventional Commits (`feat:`, `fix:`, `test:`, `docs:`, `infra:`, `chore:`). Commit small and often, and push to `origin main` at least at the end of every phase.
- `.github/workflows/ci.yml` runs build, lint and the cloud-free tests on every push and pull request. Keep it green.
- Never force-push `main`. Never commit build output, dependency folders (`node_modules`, `target`, `bin`, `obj`, `.venv`) or state files.

## 11. Project-specific rules

- **The deliverable is test assets, not the SUT.** Keep the SUT small. Invest in clear Gherkin, page objects / screenplay-style helpers, test data builders, and readable reports.
- Every suite writes Allure results to `reports/allure-results/<suite>`. `scripts/report.sh` merges them into one Allure HTML report with environment info (local / cloud, git SHA).
- Test strategy docs: `docs/test-strategy.md` (scope, levels, risk-based priorities, entry/exit criteria), `docs/traceability.md` (requirement → scenario IDs), `docs/defects/` (defect template + 2 example defect reports found while building, such as a seeded bug toggled by `SUT_BUG_ROUNDING=1`), `docs/qa-report-<phase>.md` (results summary).
- LLM validation must be **reproducible**: a fixed golden set (`llm-eval/golden/*.jsonl`), temperature 0, stored baselines (`llm-eval/baselines/<provider>.json`), and thresholds in config. Drift = metric delta versus the baseline beyond tolerance.
- AI productivity tools: record in `docs/AI_USAGE.md` how AI assistants accelerated test design and exploratory testing (with a prompt log of 3–5 real examples) and how their suggestions were verified.
- Mobile: if no Android emulator is available locally, the Phase 1 proof for mobile comes from the CI emulator job (download its artifacts into `proof/phase1-local/tests/mobile-ci/`). Note this in the proof README.

## 12. Definition of done

- [ ] Every stack item in §2 is used in running code. Cross-check with the coverage matrix in `SPECS.md` §2 and tick each row in `PROGRESS.md`.
- [ ] Phase 1 proof is complete, and all tests are green locally and in CI.
- [ ] Phase 2 proof is complete: cloud screenshots, a cloud test run and the resource list.
- [ ] Phase 3: everything is destroyed and `verify-destroyed.txt` shows nothing billable left.
- [ ] `docs/PORTFOLIO.md` and `README.md` are written, and everything is committed and pushed.
