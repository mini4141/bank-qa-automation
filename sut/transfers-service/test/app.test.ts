import assert from "node:assert/strict";
import { test } from "node:test";
import { AccountsUnavailableError } from "../src/accounts-client.ts";
import { buildApp } from "../src/app.ts";

test("returns 503 with a clear error when accounts is down", async () => {
  const db = { query: async () => ({ rowCount: 0, rows: [] }) } as never;
  const down = {
    withdraw: async () => { throw new AccountsUnavailableError("down"); },
    deposit: async () => {},
  };
  const app = buildApp(db, down);
  const res = await app.inject({ method: "POST", url: "/transfers", payload: { fromId: "a", toId: "b", amountMinor: 100 } });
  assert.equal(res.statusCode, 503);
  assert.equal(res.json().error, "ACCOUNTS_UNAVAILABLE");
  await app.close();
});
