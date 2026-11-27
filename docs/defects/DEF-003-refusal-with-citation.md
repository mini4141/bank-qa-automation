# DEF-003: a refusal answer carried a citation when the real model (Bedrock) wrote it

| Field | Value |
|---|---|
| Severity | minor (misleading source link under an "I don't know") |
| Priority | P3 |
| Status | fixed and verified in the cloud |
| Found by | API scenario "An out-of-scope question is declined without citations" on the first AWS run |
| Environment | AWS (ECS Fargate, Bedrock Nova Lite); passes against the mock |
| Requirement | REQ-CHAT-2 |

## Steps to reproduce
1. Deploy with `scripts/deploy.sh`.
2. `POST /api/chat/chat` with `{"question": "What is the weather in Paris today?"}`.

## Expected result
A refusal and an empty `citations` list.

## Actual result
The answer said it did not know, but the model appended `[account-opening]`, so the response listed that document as a source.

## Root cause and fix
The mock LLM never produces this, so the local suites could not see it. `RagIndex.answer` now drops citations when the answer is a refusal. Unit test `test_a_refusal_never_carries_citations` pins it, and the cloud API and eval runs passed after redeploying the chat image.

## Lesson
Running the same API contract against a real model finds output-format drift that a deterministic mock hides. This is why the Phase 2 Bedrock run exists.
