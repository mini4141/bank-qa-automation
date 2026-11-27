# Test strategy

ISTQB-style, risk based, deliberately shallow: one happy path per feature, because the test assets are the product.

## Scope
In scope: accounts, transfers (fee, idempotency, insufficient funds), the web app, the inquiry chat (RAG answers), non-functional performance of transfers, and AI-quality attributes of the chat (accuracy, hallucination, bias, drift, robustness, prompt injection).
Out of scope: native mobile apps, full banking rules, security penetration testing.

## Test levels
| Level | Tooling | Where |
|---|---|---|
| Unit (SUT) | node:test, pytest | `sut/*`, `sut-unit` job |
| Service / API (contract-style) | Cucumber + Rest-Assured | `tests/api` |
| UI (desktop browsers) | Playwright BDD, Chromium + WebKit | `tests/web` |
| UI (mobile web) | Appium 2 + WebdriverIO + Cucumber, Android emulator | `tests/mobile` |
| Non-functional | Gatling simulation with assertions, wrk smoke | `tests/perf` |
| AI validation | pytest harness with golden sets | `llm-eval` |
| Microservices deployment | same API suite against kind | `scripts/k8s-test.sh` |

## Risk-based priorities
1. Money movement (fee rounding, double submit, insufficient funds): API and web, tagged `@smoke`.
2. Dependency failure (transfers depends on accounts): `resilience.feature`.
3. Wrong or invented answers from the assistant: retrieval, faithfulness and hallucination gates.
4. Unfair treatment by name, gender or nationality: bias parity.
5. Silent model change: drift against stored baselines.

## Environments and test data
Local Docker Compose, kind (Kubernetes) and AWS (ECS Fargate). Data comes from builders (`AccountBuilder`), the `seed_test_data` MCP tool and `scripts/seed.sh`. Every scenario creates its own accounts.

## Entry and exit criteria
Entry: SUT healthy (`docker compose up --wait`), seed data loaded.
Exit: all suites green, Gatling assertions pass (p95 < 500 ms, failures < 1%), LLM metrics above the thresholds in `llm-eval/config.yaml` and within drift tolerance, merged Allure report published.

## Defect handling
Defects use the template in `docs/defects/`; severity follows customer money impact. Regression is the `@regression` tag on every feature.
