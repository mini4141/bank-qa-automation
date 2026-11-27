import { mkdirSync, writeFileSync } from "node:fs";
import path from "node:path";

const screenshotDir = path.resolve("../../reports/mobile-screenshots");

export const config: WebdriverIO.Config = {
  runner: "local",
  hostname: process.env.APPIUM_HOST ?? "127.0.0.1",
  port: Number(process.env.APPIUM_PORT ?? 4723),
  specs: ["./features/**/*.feature"],
  maxInstances: 1,
  capabilities: [
    {
      platformName: "Android",
      browserName: "chrome",
      "appium:automationName": "UiAutomator2",
      "appium:deviceName": "Android Emulator",
      "appium:chromedriverAutodownload": true,
      "appium:newCommandTimeout": 240,
      "wdio:enforceWebDriverClassic": true, // Appium chromedriver sessions do not speak WebDriver BiDi
      "goog:chromeOptions": { args: ["--no-first-run", "--disable-fre", "--no-default-browser-check"] },
    } as unknown as WebdriverIO.Capabilities,
  ],
  logLevel: "warn",
  waitforTimeout: 15_000,
  connectionRetryCount: 2,
  framework: "cucumber",
  cucumberOpts: {
    require: ["./steps/*.ts"],
    timeout: 90_000,
  },
  reporters: [
    "spec",
    ["allure", { outputDir: "../../reports/allure-results/mobile", useCucumberStepReporter: true, disableWebdriverStepsReporting: true }],
  ],
  /** Attach a screenshot of the device after every scenario (kept as proof and shown in Allure). */
  afterScenario: async (world) => {
    mkdirSync(screenshotDir, { recursive: true });
    const name = world.pickle.name.replace(/[^a-z0-9]+/gi, "-").toLowerCase();
    const png = await browser.takeScreenshot();
    writeFileSync(path.join(screenshotDir, `${name}.png`), Buffer.from(png, "base64"));
    const { default: allure } = await import("@wdio/allure-reporter");
    allure.addAttachment("device screenshot", Buffer.from(png, "base64"), "image/png");
  },
};
