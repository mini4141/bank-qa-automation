import { expect, type Page } from "@playwright/test";

export class AccountPage {
  constructor(private readonly page: Page) {}

  get summary() {
    return this.page.getByTestId("account-summary");
  }

  get name() {
    return this.page.getByTestId("account-name");
  }

  get balance() {
    return this.page.getByTestId("account-balance");
  }

  get id() {
    return this.page.getByTestId("account-id");
  }

  async visit(accountId: string) {
    await this.page.goto(`/#/accounts/${accountId}`);
    await expect(this.name).toBeVisible();
  }

  async accountId(): Promise<string> {
    return (await this.id.textContent()) ?? "";
  }

  async deposit(dollars: string) {
    await this.page.getByTestId("deposit-amount").fill(dollars);
    await this.page.getByTestId("deposit-submit").click();
  }

  async transfer(toId: string, dollars: string) {
    await this.page.getByTestId("transfer-to").fill(toId);
    await this.page.getByTestId("transfer-amount").fill(dollars);
    await this.page.getByTestId("transfer-submit").click();
  }

  get transferResult() {
    return this.page.getByTestId("transfer-result");
  }

  get transactions() {
    return this.page.getByTestId("transaction-row");
  }
}
