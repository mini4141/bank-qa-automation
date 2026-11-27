# Traceability: requirement to scenarios

Requirement ids appear as tags (`@REQ-...`) in the feature files.

| Requirement | Statement | Scenarios |
|---|---|---|
| REQ-ACC-1 | A customer can open a savings or checking account | api `accounts.feature` open; web REQ-WEB-1; mobile REQ-MOB-1 |
| REQ-ACC-2 | A deposit increases the balance | api deposit scenario |
| REQ-ACC-3 | An unknown account is reported as not found | api 404 scenario |
| REQ-TRF-1 | A transfer charges a 1.5% fee, rounded to the nearest cent | api happy transfer; web REQ-WEB-2; mobile REQ-MOB-2; unit `fee.test.ts` |
| REQ-TRF-2 | Retrying with the same idempotency key does not move money twice | api idempotent retry |
| REQ-TRF-3 | A transfer above the balance is rejected | api insufficient funds |
| REQ-TRF-4 | Transfers are listed per account | api list; web REQ-WEB-3 |
| REQ-RES-1 | Transfers fails with 503 and a clear error when accounts is down | api `resilience.feature` (compose, kind) |
| REQ-CON-1/2 | Each service has a health endpoint; the account payload shape is stable | api `contracts.feature` |
| REQ-CHAT-1 | Answers are grounded in the FAQ and cite their source | api chat; web REQ-WEB-4; mobile REQ-MOB-3; llm-eval retrieval + faithfulness |
| REQ-CHAT-2 | Out-of-scope questions are declined | api chat; llm-eval hallucination |
| REQ-CHAT-3 | Answers do not depend on name, gender or nationality | llm-eval bias |
| REQ-CHAT-4 | Typos and paraphrases still get the right answer | llm-eval robustness |
| REQ-CHAT-5 | Instructions hidden in a question are not followed | llm-eval injection |
| REQ-CHAT-6 | Quality does not silently change between model versions | llm-eval drift |
| REQ-NFR-1 | Transfer p95 under 500 ms, under 1% failures at 50 users | Gatling `TransferSimulation` |
| REQ-WEB-5 | The account page keeps its look | web visual snapshot |
