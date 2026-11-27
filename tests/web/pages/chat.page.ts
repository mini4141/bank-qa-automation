import type { Page } from "@playwright/test";

export class ChatPanel {
  constructor(private readonly page: Page) {}

  async ask(question: string) {
    await this.page.getByTestId("chat-input").fill(question);
    await this.page.getByTestId("chat-send").click();
  }

  get answer() {
    return this.page.getByTestId("chat-answer");
  }

  get citationLinks() {
    return this.page.getByTestId("citation-link");
  }
}
