import { createBdd } from "playwright-bdd";
import { expect, test } from "./fixtures";

const { Given, When, Then } = createBdd(test);

Given("I am on the bank home page", async ({ openAccountPage }) => {
  await openAccountPage.open();
});

When("I open a {string} account for {string}", async ({ openAccountPage }, type: string, name: string) => {
  await openAccountPage.openAccount(name, type as "savings" | "checking");
});

Then("I see the account page for {string} with balance {string}", async ({ accountPage, world }, name: string, balance: string) => {
  await expect(accountPage.name).toHaveText(name);
  await expect(accountPage.balance).toHaveText(balance);
  world.accountId = await accountPage.accountId();
});

Given("I have an account {string} with balance {int}", async ({ bank, accountPage, world }, name: string, dollars: number) => {
  world.accountId = await bank.createAccount(name, dollars);
  await accountPage.visit(world.accountId);
});

Given("another customer account exists", async ({ bank, world }) => {
  world.otherId = await bank.createAccount("Other Customer", 0);
});

When("I transfer {string} dollars to the other account", async ({ accountPage, world }, dollars: string) => {
  await accountPage.transfer(world.otherId!, dollars);
});

Then("the transfer confirmation shows a fee of {string}", async ({ accountPage }, fee: string) => {
  await expect(accountPage.transferResult).toContainText(`Fee ${fee}`);
});

Then("my balance is {string}", async ({ accountPage }, balance: string) => {
  await expect(accountPage.balance).toHaveText(balance);
});

Then("the transaction list shows {int} entry with {string}", async ({ accountPage }, count: number, text: string) => {
  await expect(accountPage.transactions).toHaveCount(count);
  await expect(accountPage.transactions.first()).toContainText(text);
});

When("I ask the assistant {string}", async ({ chat }, question: string) => {
  await chat.ask(question);
});

Then("the answer links to the source {string}", async ({ chat }, title: string) => {
  await expect(chat.answer).toBeVisible();
  const link = chat.citationLinks.first();
  await expect(link).toContainText(title);
  await expect(link).toHaveAttribute("href", /\/api\/chat\/docs\/cardless-atm$/);
});

Then("the account page looks as expected", async ({ accountPage }) => {
  await expect(accountPage.summary).toHaveScreenshot("account-page.png", { mask: [accountPage.id], stylePath: "snapshot.css" });
});
