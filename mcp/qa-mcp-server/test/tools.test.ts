import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { test } from "node:test";
import { listFlakyTests } from "../src/tools.ts";

test("a test that failed and passed within the window is flaky", () => {
  const file = path.join(mkdtempSync(path.join(tmpdir(), "hist-")), "history.json");
  writeFileSync(file, JSON.stringify([
    { runId: "1", results: { a: "passed", b: "passed", c: "failed" } },
    { runId: "2", results: { a: "failed", b: "passed", c: "failed" } },
    { runId: "3", results: { a: "passed", b: "passed", c: "failed" } },
  ]));
  assert.deepEqual(listFlakyTests(10, file), ["a"]);
});
