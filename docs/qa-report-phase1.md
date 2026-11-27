# QA report: Phase 1 (local)

Build: `main` at the end of Phase 1. Environment: Docker Compose on Windows 11 (local) and GitHub Actions (Ubuntu 24.04, Android emulator API 34, kind). Seeded bug off unless stated.

## Results
| Layer | Tests | Result | Notes |
|---|---|---|---|
| SUT unit (node:test, pytest) | 12 | pass | accounts 3, transfers 3, inquiry-chat 3, MCP 1, plus lint (tsc, ruff) |
| API (Cucumber + Rest-Assured) | 14 scenarios | pass | accounts, transfers, chat, contracts, resilience |
| API on Kubernetes (kind) | 14 scenarios | pass | same suite, `SUT_RUNTIME=k8s` scales the accounts deployment to zero |
| Web (Playwright BDD) | 5 scenarios x 2 browsers | pass | Chromium and WebKit, visual snapshot on both |
| Mobile web (Appium) | 3 scenarios | pass in CI | Chrome on an Android emulator; no emulator on the dev PC |
| Performance (Gatling) | 1 simulation, 2 assertions | pass | 50 users over 60 s, 250 requests, transfer p95 45 ms (limit 500), 0% failures |
| wrk smoke | GET /accounts/:id, 10 s | pass | about 1,200 requests/s, p99 41 ms |
| LLM evaluation (mock) | 8 tests | pass | see below |
| Merged Allure report | 34 results | all passed | published to GitHub Pages |

## LLM evaluation (mock provider)
| Metric | Value | Threshold |
|---|---|---|
| retrieval hit@3 | 1.00 | 0.90 |
| faithfulness | 1.00 | 0.85 |
| hallucination refusal rate | 1.00 | 1.00 |
| bias parity | 1.00 | 1.00 |
| robustness | 1.00 | 0.80 |
| injection resistance | 1.00 | 1.00 |
| drift (max absolute change vs baseline) | 0.00 | 0.10 |
| latency p95 | about 70 ms | 2000 ms |

## Defects
| Id | Summary | Status |
|---|---|---|
| DEF-001 | Fee rounded up when `SUT_BUG_ROUNDING=1` (seeded); caught by API and web suites | verified |
| DEF-002 | Assistant answers differed by name and one out-of-scope question was answered (found by the first LLM-eval run) | fixed |

## Risks and gaps
- Mobile runs only in CI; its evidence is in `proof/phase1-local/tests/mobile-ci/`.
- Mock LLM is extractive and deterministic, so it cannot show the variability of a real model; the Bedrock run in Phase 2 covers that and records its own baseline.
- Visual baselines are per platform (Windows locally, Linux in CI).
- CI exposed flakiness in mobile steps on a slow emulator; steps now wait explicitly and submit with the keyboard.

## Exit criteria
All suites green locally and in CI, Gatling assertions passed, LLM metrics above thresholds and within drift tolerance, merged report published: **met**.
