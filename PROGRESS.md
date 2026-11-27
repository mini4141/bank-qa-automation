# PROGRESS

Resume from the first unticked item. Current phase: **2** (Phase 0 and 1 done; CI green, Pages live)

## Phases
- [x] Phase 0 scaffold
- [x] Phase 1 local (proof/phase1-local)
- [ ] Phase 2 AWS showcase (proof/phase2-cloud)
- [ ] Phase 3 destroy (proof/phase3-destroy)
- [ ] Phase 4 write-up (docs/PORTFOLIO.md)

## Coverage matrix (SPECS §2)
- [x] Test scenarios from requirements; functional + non-functional (Gherkin, traceability, Gatling)
- [x] Test data, tools, environments (builders, `seed_test_data`, compose/kind/AWS)
- [x] Execute + document results; defects; analyse and report (Allure, docs/defects, qa-report)
- [x] Automation + manual/exploratory validation (docs/exploratory-charters.md)
- [x] Regression coverage, test documentation (@regression tags)
- [x] Appium / Playwright / Rest-Assured
- [x] Cucumber across the three functional suites
- [x] CI/CD GitHub Actions matrix + Pages
- [x] Microservices testing (contract-style checks, kind job, service-down scenario)
- [x] AI tools for test design (docs/AI_USAGE.md)
- [x] Prompt engineering + RAG validation (retrieval + faithfulness)
- [x] OpenAI SDK client, Secrets Manager, MCP in CI
- [x] Bias / drift / hallucination / performance monitoring of AI
- [x] ISTQB-style process, Gatling + wrk, Docker/K8s, bash

## Phase 1 proof (SPECS §9)
- [x] tests/allure-report (merged HTML), tests/gatling, tests/llm-eval/report.html, tests/mobile-ci
- [x] screenshots 01-allure-overview, 02-allure-api-feature, 03-playwright-trace, 04-gatling-report, 05-llm-eval-summary, 06-bug-caught-rounding, 07-github-pages-report, 08-ci-matrix
- [x] logs/mcp-ci-client.log, logs/k8s-api-job.log, docs/defects/DEF-001-fee-rounding.md

## Phase 2 proof (SPECS §10)
- [ ] tests/allure-report-cloud, tests/llm-eval-bedrock/report.html, logs/drift-mock-vs-bedrock.json
- [ ] screenshots 01-cloud-allure, 02-cloud-web-app, 03-bedrock-eval
- [ ] resources.txt

## Phase 3 proof (SPECS §11)
- [ ] terraform destroy; verify-destroyed.txt shows nothing billable

## Build items
- [x] sut: accounts, transfers, web, inquiry-chat (+mock-llm), docker compose
- [x] tests/api (Cucumber+Rest-Assured >=6 scenarios)
- [x] tests/web (Playwright BDD >=5, chromium+webkit)
- [x] tests/mobile (Appium >=3, CI emulator)
- [x] tests/perf (Gatling + wrk)
- [x] llm-eval (6 categories, drift baselines)
- [x] mcp/qa-mcp-server + ci-client
- [x] deploy/k8s + kind CI job
- [ ] infra Terraform + deploy/destroy/verify scripts
- [x] docs: test-strategy, traceability, exploratory-charters, defects (2), qa-report, AI_USAGE
