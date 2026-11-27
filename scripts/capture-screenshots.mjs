// Headless screenshots for the proof folder. Usage: node scripts/capture-screenshots.mjs <phase1|phase2>
// Reports are served over HTTP from ./reports because Allure fetches its data files.
import { createServer } from "node:http";
import { existsSync, mkdirSync, readFileSync, readdirSync, statSync } from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const { chromium } = createRequire(path.join(root, "tests/web/package.json"))("@playwright/test");
const phase = process.argv[2];
const out = path.join(root, `proof/${phase === "phase1" ? "phase1-local" : "phase2-cloud"}/screenshots`);
mkdirSync(out, { recursive: true });

const types = { ".html": "text/html", ".js": "text/javascript", ".json": "application/json", ".css": "text/css", ".png": "image/png", ".svg": "image/svg+xml", ".zip": "application/zip", ".woff2": "font/woff2" };
const server = createServer((req, res) => {
  const file = path.join(root, "reports", decodeURIComponent(req.url.split("?")[0]));
  if (existsSync(file) && statSync(file).isFile()) {
    res.writeHead(200, { "content-type": types[path.extname(file)] ?? "application/octet-stream" });
    res.end(readFileSync(file));
  } else {
    res.writeHead(404).end();
  }
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const base = `http://127.0.0.1:${server.address().port}`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1360, height: 900 } });

async function shot(name, url, { wait = 2500, fullPage = false } = {}) {
  await page.goto(url, { waitUntil: "load" });
  await page.waitForTimeout(wait);
  await page.screenshot({ path: path.join(out, `${name}.png`), fullPage });
  console.log(`captured ${name}`);
}

function latestDir(dir, prefix) {
  const abs = path.join(root, "reports", dir);
  const found = readdirSync(abs).filter((d) => d.startsWith(prefix)).sort();
  return `${dir}/${found.at(-1)}`;
}

if (phase === "phase1") {
  await shot("01-allure-overview", `${base}/allure-report/index.html`);
  await shot("02-allure-api-feature", `${base}/allure-report/index.html#behaviors`);
  const dataDir = path.join(root, "reports/playwright-html/data");
  const trace = existsSync(dataDir) ? readdirSync(dataDir).find((f) => f.endsWith(".zip")) : undefined;
  if (trace) await shot("03-playwright-trace", `${base}/playwright-html/trace/index.html?trace=${base}/playwright-html/data/${trace}`, { wait: 5000 });
  else await shot("03-playwright-trace", `${base}/playwright-html/index.html`);
  await shot("04-gatling-report", `${base}/${latestDir("gatling", "transfersimulation-")}/index.html`, { wait: 3000 });
  await shot("05-llm-eval-summary", `${base}/llm-eval/report.html`);
  await shot("06-bug-caught-rounding", `${base}/allure-report-bug/index.html#suites`);
  await shot("07-github-pages-report", process.env.PAGES_URL, { wait: 5000 });
  await shot("08-ci-matrix", process.env.CI_RUN_URL, { wait: 4000, fullPage: true });
} else {
  await shot("01-cloud-allure", `${base}/allure-report-cloud/index.html`);
  const web = process.env.WEB_URL;
  await page.goto(web);
  await page.getByTestId("account-name-input").fill("Cloud Demo");
  await page.getByTestId("open-account-submit").click();
  await page.getByTestId("account-name").waitFor();
  await page.getByTestId("chat-input").fill("How long is a cardless ATM code valid?");
  await page.getByTestId("chat-send").click();
  await page.getByTestId("chat-answer").waitFor({ timeout: 60000 });
  await page.screenshot({ path: path.join(out, "02-cloud-web-app.png"), fullPage: true });
  console.log("captured 02-cloud-web-app");
  await shot("03-bedrock-eval", `${base}/llm-eval-bedrock/report.html`);
}

await browser.close();
server.close();
