# DEF-001: transfer fee rounded up instead of to the nearest cent

| Field | Value |
|---|---|
| Severity | major (customers overcharged) |
| Priority | P2 |
| Status | verified (seeded defect, toggled by `SUT_BUG_ROUNDING=1`) |
| Found by | API scenario "Happy path transfer charges the fee" and web scenario "Transfer money via the UI and see the fee" |
| Environment | local compose |
| Requirement | REQ-TRF-1 |

## Steps to reproduce
1. Start the SUT with `SUT_BUG_ROUNDING=1 docker compose up -d transfers`.
2. Create two accounts and fund the sender with 100.00.
3. Transfer 10.10 from sender to receiver.

## Expected result
Fee is 1.5% of 10.10 = 0.1515, rounded to 0.15. Sender balance 89.75.

## Actual result
Fee is 0.16 and the sender balance is 89.74. The API step fails with `expected: 15L`; the web test fails with `Expected substring: "Fee $0.15"`, `Received string: "Transfer sent. Fee $0.16"`.

## Evidence
`proof/phase1-local/logs/bug-rounding-api.log`, `proof/phase1-local/logs/bug-rounding-web.log`, screenshot `06-bug-caught-rounding.png`.

## Root cause and fix
`computeFee` used `Math.ceil` when the flag was set. With the flag off it uses `Math.round`; unit test `fee.test.ts` pins both behaviours.
