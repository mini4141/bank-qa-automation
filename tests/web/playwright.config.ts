import { defineConfig, devices } from "@playwright/test";
import { defineBddConfig } from "playwright-bdd";

const testDir = defineBddConfig({
  features: "features/*.feature",
  steps: ["steps/*.ts"],
});

export default defineConfig({
  testDir,
  timeout: 30_000,
  expect: { toHaveScreenshot: { maxDiffPixelRatio: 0.1 } },
  snapshotPathTemplate: "snapshots/{arg}-{projectName}-{platform}{ext}",
  reporter: [
    ["list"],
    ["junit", { outputFile: "../../reports/junit/web.xml" }],
    ["allure-playwright", { resultsDir: "../../reports/allure-results/web" }],
    ["html", { open: "never", outputFolder: "../../reports/playwright-html" }],
  ],
  use: {
    baseURL: process.env.WEB_URL ?? "http://localhost:8080",
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
  },
  outputDir: "../../reports/playwright-output",
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],
});
