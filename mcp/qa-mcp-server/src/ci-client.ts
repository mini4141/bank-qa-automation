/**
 * CI step: starts the MCP server over stdio and calls its tools.
 *   node src/ci-client.ts seed      -> seed_test_data before the suites
 *   node src/ci-client.ts summary   -> get_report_summary + list_flaky_tests after the suites,
 *                                      written to the GitHub job summary
 */
import { appendFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

const serverPath = path.join(path.dirname(fileURLToPath(import.meta.url)), "server.ts");
const client = new Client({ name: "ci-client", version: "1.0.0" });
await client.connect(new StdioClientTransport({ command: process.execPath, args: [serverPath] }));

async function call(name: string, args: Record<string, unknown> = {}) {
  console.log(`[mcp] tools/call ${name} ${JSON.stringify(args)}`);
  const res = await client.callTool({ name, arguments: args });
  const text = (res.content as { text: string }[])[0].text;
  console.log(`[mcp] ${name} -> ${res.isError ? "ERROR " : ""}${text}`);
  if (res.isError) throw new Error(`${name} failed: ${text}`);
  return JSON.parse(text);
}

const tools = await client.listTools();
console.log(`[mcp] connected, tools: ${tools.tools.map((t) => t.name).join(", ")}`);

const mode = process.argv[2];
if (mode === "seed") {
  await call("seed_test_data", { profile: "demo" });
} else if (mode === "summary") {
  const summary = await call("get_report_summary");
  const { flaky } = await call("list_flaky_tests", { lastRuns: 10 });
  const table = [
    "## Test results (via MCP `get_report_summary`)",
    "",
    "| Total | Passed | Failed | Broken | Skipped | Pass rate |",
    "|---|---|---|---|---|---|",
    `| ${summary.total} | ${summary.passed} | ${summary.failed} | ${summary.broken} | ${summary.skipped} | ${summary.passRate}% |`,
    "",
    `Flaky tests in the last runs: ${flaky.length ? flaky.join(", ") : "none"}`,
    "",
  ].join("\n");
  console.log(table);
  if (process.env.GITHUB_STEP_SUMMARY) appendFileSync(process.env.GITHUB_STEP_SUMMARY, table);
} else {
  throw new Error("usage: ci-client.ts seed|summary");
}
await client.close();
