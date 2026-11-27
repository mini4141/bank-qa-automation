# Decisions

One line each: date, decision, reason.

- 2026-11-27 | Maven 3.9.9 installed manually to `~/tools` | `winget` has no Apache.Maven package; zip from archive.apache.org.
- 2026-11-27 | SUT services run TypeScript directly on Node 24 (native type stripping), no build step | Simplest; fewer moving parts.
- 2026-11-27 | Services accept an optional `ROUTE_PREFIX` (e.g. `/api/accounts`) | ALB path routing without URL rewrite; locally the prefix is empty.
- 2026-11-27 | Mock LLM and inquiry-chat share one Python image (`sut/inquiry-chat`) | One build, deterministic extractive mock beside the real service.
- 2026-11-27 | Bedrock chat via boto3 Converse behind the same `LLM` interface; embeddings via Titan v2 | Allowed fallback; OpenAI-compatible Bedrock endpoint needs separate API keys.
- 2026-11-27 | Python via `uv` pinned to 3.12 (host has 3.14) | Spec requires 3.12.
- 2026-11-27 | `wrk` runs in a Docker image locally (no native Windows build) and natively (apt) in CI | Host is Windows.
- 2026-11-27 | GitHub owner is `mini4141` (gh login); resource tag `Owner=alvieirvansyah` as required | CLAUDE.md tag rule.
- 2026-11-27 | Bedrock chat model apac.amazon.nova-lite-v1:0 (Converse), embeddings Titan v2 | cheapest on-demand model available in ap-southeast-2, no Marketplace subscription.
- 2026-11-27 | Pages deploy lives in ci.yml report job (no separate pages.yml); Playwright pinned 1.57.0 (playwright-bdd incompat with 1.65); CI on ubuntu-24.04
- 2026-11-27 | RDS connection uses sslmode=no-verify | RDS Postgres 16 forces TLS; certificate verification skipped inside the VPC for the ephemeral showcase.
