# How AI tools were used

AI coding assistants (Claude Code in this repository; the same workflow applies to Cursor, Copilot, Gemini and NotebookLM) were used as accelerators, never as an oracle. Every suggestion was run before it was kept.

## Where they helped
- **Test design:** turning the requirements in `SPECS.md` into Gherkin scenarios, boundary values for the fee rounding (10.10 gives 0.1515, a case where round and ceil differ), and the risk list in `docs/test-strategy.md`.
- **Exploratory testing:** proposing charters and odd inputs (typos, paraphrases, mixed-topic questions) for the assistant; the useful ones became golden-set items.
- **Boilerplate:** page objects, Rest-Assured client, MCP server plumbing, Terraform resources.
- **Failure analysis:** reading Allure and Maven failures to find the cause quickly.

## How output was verified
1. Everything is executed: a suggestion that is not covered by a green run, a unit test or a manual check was not accepted.
2. Tests must be able to fail: the seeded bug (`SUT_BUG_ROUNDING=1`) proves the API and web suites go red for the right reason (DEF-001), and the first LLM-eval run exposed two real weaknesses (DEF-002).
3. Generated library calls were checked against the installed version (for example `playwright-bdd` was incompatible with the newest Playwright, so Playwright is pinned to 1.57.0).
4. Secrets never go into prompts or the repo; credentials live in `.env` (gitignored) or AWS Secrets Manager.
5. LLM evaluation uses temperature 0, fixed golden sets, stored baselines and thresholds in config, so an AI-assisted change to a prompt shows up as drift.

## Prompt log (real examples)
| # | Prompt (shortened) | What it produced | How it was checked |
|---|---|---|---|
| 1 | "From these requirements write Gherkin for transfers: happy path with fee, idempotent retry, insufficient funds. Use cents to avoid float errors." | The three scenarios in `transfers.feature`, amounts as strings converted to minor units | Ran against compose; flipped the bug flag to see the fee scenario fail |
| 2 | "List 10 questions a customer might type about cardless ATM withdrawals, including typos and paraphrases, and say which FAQ document should answer." | Seeds for `golden/qa.jsonl` and `golden/robustness.jsonl` | Retrieval hit@3 measured; items the mock got wrong were fixed in the SUT, not deleted |
| 3 | "Design paired prompts that differ only in name, gender or nationality to test eligibility answers." | `golden/bias_pairs.jsonl` | First run found parity 0.67 (DEF-002) |
| 4 | "Write a judge prompt that returns JSON saying whether every claim in ANSWER is supported by CONTEXT." | `JUDGE_SYSTEM` in `llm-eval/harness/judge.py` | Added a citation-overlap fallback for unparsable judge replies |
| 5 | "Exploratory charter: what could go wrong when transfers depends on accounts and accounts is down?" | Charter 4 and `resilience.feature` | Scenario stops the compose service; found that on kind the pod must be awaited before the call |

Paid tools such as NotebookLM, Gemini, Cursor and Copilot are described here as part of the workflow; this repository does not integrate them.
