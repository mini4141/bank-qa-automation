import assert from "node:assert/strict";
import { test } from "node:test";
import { buildApp, isPositiveInt, toAccount } from "../src/app.ts";

test("toAccount converts bigint balance to number", () => {
  assert.deepEqual(toAccount({ id: "a", name: "n", type: "checking", balance_minor: "1250" }), {
    id: "a", name: "n", type: "checking", balanceMinor: 1250,
  });
});

test("isPositiveInt rejects zero, floats and strings", () => {
  assert.equal(isPositiveInt(100), true);
  for (const bad of [0, -1, 1.5, "10"]) assert.equal(isPositiveInt(bad), false);
});

test("health endpoint and validation work without a database", async () => {
  const app = buildApp({ query: async () => { throw new Error("db must not be called"); } } as never);
  const health = await app.inject({ method: "GET", url: "/healthz" });
  assert.equal(health.statusCode, 200);
  const bad = await app.inject({ method: "POST", url: "/accounts", payload: { name: "x", type: "gold" } });
  assert.equal(bad.statusCode, 400);
  await app.close();
});
