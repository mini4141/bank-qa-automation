# PROGRESS

Resume from the first unticked item. Current phase: **0**

## Phases
- [ ] Phase 0 scaffold
- [ ] Phase 1 local (proof/phase1-local)
- [ ] Phase 2 AWS showcase (proof/phase2-cloud)
- [ ] Phase 3 destroy (proof/phase3-destroy)
- [ ] Phase 4 write-up (docs/PORTFOLIO.md)

## Coverage matrix (SPECS §2)
- [ ] Test scenarios from requirements; functional + non-functional (Gherkin, traceability, Gatling)
- [ ] Test data, tools, environments (builders, `seed_test_data`, compose/kind/AWS)
- [ ] Execute + document results; defects; analyse and report (Allure, docs/defects, qa-report)
- [ ] Automation + manual/exploratory validation (docs/exploratory-charters.md)
- [ ] Regression coverage, test documentation (@regression tags)
- [ ] Appium / Playwright / Rest-Assured
- [ ] Cucumber across the three functional suites
- [ ] CI/CD GitHub Actions matrix + Pages
- [ ] Microservices testing (contract-style checks, kind job, service-down scenario)
- [ ] AI tools for test design (docs/AI_USAGE.md)
- [ ] Prompt engineering + RAG validation (retrieval + faithfulness)
- [ ] OpenAI SDK client, Secrets Manager, MCP in CI
- [ ] Bias / drift / hallucination / performance monitoring of AI
- [ ] ISTQB-style process, Gatling + wrk, Docker/K8s, bash

## Phase 1 proof (SPECS §9)
- [ ] tests/allure-report (merged HTML), tests/gatling, tests/llm-eval/report.html, tests/mobile-ci
- [ ] screenshots 01-allure-overview, 02-allure-api-feature, 03-playwright-trace, 04-gatling-report, 05-llm-eval-summary, 06-bug-caught-rounding, 07-github-pages-report, 08-ci-matrix
- [ ] logs/mcp-ci-client.log, logs/k8s-api-job.log, docs/defects/DEF-001-fee-rounding.md

## Phase 2 proof (SPECS §10)
- [ ] tests/allure-report-cloud, tests/llm-eval-bedrock/report.html, logs/drift-mock-vs-bedrock.json
- [ ] screenshots 01-cloud-allure, 02-cloud-web-app, 03-bedrock-eval
- [ ] resources.txt

## Phase 3 proof (SPECS §11)
- [ ] terraform destroy; verify-destroyed.txt shows nothing billable

## Build items
- [ ] sut: accounts, transfers, web, inquiry-chat (+mock-llm), docker compose
- [ ] tests/api (Cucumber+Rest-Assured >=6 scenarios)
- [ ] tests/web (Playwright BDD >=5, chromium+webkit)
- [ ] tests/mobile (Appium >=3, CI emulator)
- [ ] tests/perf (Gatling + wrk)
- [ ] llm-eval (6 categories, drift baselines)
- [ ] mcp/qa-mcp-server + ci-client
- [ ] deploy/k8s + kind CI job
- [ ] infra Terraform + deploy/destroy/verify scripts
- [ ] docs: test-strategy, traceability, exploratory-charters, defects (2), qa-report, AI_USAGE
