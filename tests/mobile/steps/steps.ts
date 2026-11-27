import { Given, Then, When } from "@cucumber/cucumber";
import { $, browser, expect } from "@wdio/globals";

// The emulator reaches the host machine at 10.0.2.2; the test process itself uses localhost for API setup.
const siteUrl = process.env.MOBILE_WEB_URL ?? "http://10.0.2.2:8080";
const accountsUrl = process.env.ACCOUNTS_URL ?? "http://localhost:3001";

const world: { accountId?: string; otherId?: string } = {};
const byId = (id: string) => $(`[data-testid="${id}"]`);

async function createAccount(name: string, dollars: number): Promise<string> {
  const create = await fetch(`${accountsUrl}/accounts`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ name, type: "checking" }),
  });
  const { id } = (await create.json()) as { id: string };
  if (dollars > 0) {
    await fetch(`${accountsUrl}/accounts/${id}/deposits`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ amountMinor: dollars * 100 }),
    });
  }
  return id;
}

Given("I open the bank site on the phone", async () => {
  await browser.url(siteUrl);
  await byId("home-link").waitForDisplayed();
});

When("I open a {string} account for {string} on the phone", async (type: string, name: string) => {
  await byId("account-name-input").setValue(name);
  await byId("account-type-select").selectByAttribute("value", type);
  await byId("open-account-submit").click();
});

Then("the phone shows the account page for {string}", async (name: string) => {
  await byId("account-name").waitForDisplayed({ timeout: 30_000 });
  await expect(byId("account-name")).toHaveText(name);
});

Given("a funded account {string} with {int} dollars exists", async (name: string, dollars: number) => {
  world.accountId = await createAccount(name, dollars);
});

Given("another customer account exists for the phone", async () => {
  world.otherId = await createAccount("Other Customer", 0);
});

When("I open that account on the phone", async () => {
  await browser.url(`${siteUrl}/#/accounts/${world.accountId}`);
  await byId("account-name").waitForDisplayed();
});

When("I transfer {string} dollars to the other account on the phone", async (dollars: string) => {
  await byId("transfer-to").setValue(world.otherId!);
  await byId("transfer-amount").setValue(dollars);
  // Enter submits the form like the phone keyboard "go" key; the on-screen keyboard can cover the button
  await browser.keys("Enter");
});

Then("the phone shows the transfer confirmation with a fee of {string}", async (fee: string) => {
  // slow emulator: wait for the confirmation, but surface the page error if the transfer was rejected
  await browser.waitUntil(async () => (await byId("transfer-result").isDisplayed()) || (await byId("page-error").isDisplayed()), {
    timeout: 30_000,
    timeoutMsg: "neither a transfer confirmation nor an error appeared",
  });
  if (await byId("page-error").isDisplayed()) throw new Error(`transfer rejected: ${await byId("page-error").getText()}`);
  await expect(byId("transfer-result")).toHaveText(expect.stringContaining(`Fee ${fee}`));
});

When("I ask the assistant {string} on the phone", async (question: string) => {
  await byId("chat-input").setValue(question);
  await byId("chat-send").click();
});

Then("the phone shows an answer with a source link", async () => {
  await byId("chat-answer").waitForDisplayed();
  await expect(byId("citation-link")).toBeDisplayed();
});
