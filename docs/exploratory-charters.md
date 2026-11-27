# Exploratory testing charters

Manual sessions complement the automation. Each charter was time-boxed to 30 minutes against the local compose stack.

## Charter 1: money edge cases in the transfer form
Mission: explore amounts and recipients that automation does not cover.
Notes: amounts with many decimals are rounded by the client (`toMinor`); a transfer to the same account is rejected with a generic message; pasting an account id with trailing spaces fails with a 404 instead of a friendly hint. Raised as an improvement, not a defect.

## Charter 2: assistant behaviour under odd phrasing
Mission: find questions where the chat answers confidently from the wrong document.
Notes: very short questions ("fees?") retrieve the fees document, but a question mixing two topics ("loan and cardless limits") answers only one; the answer is faithful but incomplete. The paraphrase cases went into the robustness golden set.

## Charter 3: small screens
Mission: use the app on a 375 px wide viewport.
Notes: forms stack correctly; the long account id wraps because of `word-break`. No horizontal scroll. Covered later by the mobile suite.

## Charter 4: failure during a transfer
Mission: stop accounts mid-use.
Notes: transfers returns 503 with a readable message and the web page shows it. This became `resilience.feature`.
