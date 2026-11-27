import { spawn } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../..");
const REPORTS = path.join(REPO_ROOT, "reports");

const accountsUrl = () => process.env.ACCOUNTS_URL ?? "http://localhost:3001";

async function post(url: string, body: unknown): Promise<{ id: string }> {
  const res = await fetch(url, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body) });
  if (!res.ok) throw new Error(`POST ${url} failed with ${res.status}`);
  return (await res.json()) as { id: string };
}

const PROFILES: Record<string, { name: string; type: string; balanceMinor: number }[]> = {
  demo: [
    { name: "Alice Demo", type: "checking", balanceMinor: 500_000 },
    { name: "Bob Demo", type: "savings", balanceMinor: 120_000 },
  ],
  empty: [{ name: "Empty Customer", type: "checking", balanceMinor: 0 }],
};

/** Creates accounts through the public accounts API and returns their ids. */
export async function seedTestData(profile: string): Promise<{ profile: string; accounts: { id: string; name: string; balanceMinor: number }[] }> {
  const plan = PROFILES[profile];
  if (!plan) throw new Error(`unknown profile "${profile}", expected one of ${Object.keys(PROFILES).join(", ")}`);
  const accounts = [];
  for (const spec of plan) {
    const { id } = await post(`${accountsUrl()}/accounts`, { name: spec.name, type: spec.type });
    if (spec.balanceMinor > 0) await post(`${accountsUrl()}/accounts/${id}/deposits`, { amountMinor: spec.balanceMinor });
    accounts.push({ id, name: spec.name, balanceMinor: spec.balanceMinor });
  }
  return { profile, accounts };
}

/** Shells out to scripts/run-suite.sh and returns the exit code with the tail of the output. */
export function runSuite(name: string, env: string): Promise<{ suite: string; env: string; exitCode: number; outputTail: string }> {
  return new Promise((resolve, reject) => {
    const child = spawn("bash", ["scripts/run-suite.sh", name, env], { cwd: REPO_ROOT });
    let output = "";
    child.stdout.on("data", (d) => (output += d));
    child.stderr.on("data", (d) => (output += d));
    child.on("error", reject);
    child.on("close", (code) => resolve({ suite: name, env, exitCode: code ?? 1, outputTail: output.split("\n").slice(-25).join("\n") }));
  });
}

export interface Summary {
  total: number;
  passed: number;
  failed: number;
  broken: number;
  skipped: number;
  passRate: number;
}

/** Reads the statistics of the merged Allure report (reports/allure-report/widgets/summary.json). */
export function getReportSummary(reportDir = path.join(REPORTS, "allure-report")): Summary {
  const file = path.join(reportDir, "widgets", "summary.json");
  if (!existsSync(file)) throw new Error(`no merged Allure report at ${file}; run scripts/report.sh first`);
  const stat = JSON.parse(readFileSync(file, "utf8")).statistic as Record<string, number>;
  const total = stat.total ?? 0;
  return {
    total,
    passed: stat.passed ?? 0,
    failed: stat.failed ?? 0,
    broken: stat.broken ?? 0,
    skipped: stat.skipped ?? 0,
    passRate: total ? Math.round(((stat.passed ?? 0) / total) * 1000) / 10 : 0,
  };
}

interface HistoryRun {
  runId: string;
  results: Record<string, string>;
}

/** A test is flaky when it both failed and passed within the last N recorded runs. */
export function listFlakyTests(lastRuns = 10, historyFile = path.join(REPORTS, "history.json")): string[] {
  if (!existsSync(historyFile)) return [];
  const runs = (JSON.parse(readFileSync(historyFile, "utf8")) as HistoryRun[]).slice(-lastRuns);
  const seen = new Map<string, Set<string>>();
  for (const run of runs) {
    for (const [test, status] of Object.entries(run.results)) {
      seen.set(test, (seen.get(test) ?? new Set()).add(status === "passed" ? "passed" : "failed"));
    }
  }
  return [...seen].filter(([, statuses]) => statuses.size === 2).map(([test]) => test).sort();
}
