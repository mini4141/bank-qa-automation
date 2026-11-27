import assert from "node:assert/strict";
import { test } from "node:test";
import { computeFee } from "../src/fee.ts";

test("fee is 1.5% rounded to nearest minor unit", () => {
  assert.equal(computeFee(1010, false), 15); // exact 15.15
  assert.equal(computeFee(10000, false), 150);
});

test("seeded rounding bug rounds fees up", () => {
  assert.equal(computeFee(1010, true), 16);
});
