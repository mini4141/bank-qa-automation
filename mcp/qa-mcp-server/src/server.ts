import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { getReportSummary, listFlakyTests, runSuite, seedTestData } from "./tools.ts";

const server = new McpServer({ name: "qa-mcp-server", version: "1.0.0" });

const asText = (value: unknown) => ({ content: [{ type: "text" as const, text: JSON.stringify(value, null, 2) }] });
const asError = (err: unknown) => ({ isError: true, content: [{ type: "text" as const, text: (err as Error).message }] });

server.registerTool(
  "seed_test_data",
  {
    description: "Create demo bank accounts through the accounts API so suites and demos never start empty.",
    inputSchema: { profile: z.enum(["demo", "empty"]).default("demo").describe("which data set to create") },
  },
  async ({ profile }) => seedTestData(profile).then(asText, asError),
);

server.registerTool(
  "run_suite",
  {
    description: "Run one test suite (sut-unit, api, web, perf, llm-eval, mobile) against local or cloud and return the exit code.",
    inputSchema: {
      name: z.enum(["sut-unit", "api", "web", "perf", "llm-eval", "mobile"]),
      env: z.enum(["local", "cloud"]).default("local"),
    },
  },
  async ({ name, env }) => runSuite(name, env).then(asText, asError),
);

server.registerTool(
  "get_report_summary",
  { description: "Totals and pass rate from the merged Allure report.", inputSchema: {} },
  async () => {
    try {
      return asText(getReportSummary());
    } catch (err) {
      return asError(err);
    }
  },
);

server.registerTool(
  "list_flaky_tests",
  {
    description: "Tests that both failed and passed within the last N recorded runs (reports/history.json).",
    inputSchema: { lastRuns: z.number().int().min(2).max(50).default(10) },
  },
  async ({ lastRuns }) => asText({ lastRuns, flaky: listFlakyTests(lastRuns) }),
);

await server.connect(new StdioServerTransport());
