import type { Page } from "@playwright/test";

export class OpenAccountPage {
  constructor(private readonly page: Page) {}

  async open() {
    await this.page.goto("/");
  }

  async openAccount(name: string, type: "savings" | "checking") {
    await this.page.getByTestId("account-name-input").fill(name);
    await this.page.getByTestId("account-type-select").selectOption(type);
    await this.page.getByTestId("open-account-submit").click();
  }
}
