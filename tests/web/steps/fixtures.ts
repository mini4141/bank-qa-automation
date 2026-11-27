import { test as base } from "playwright-bdd";
import { AccountPage } from "../pages/account.page";
import { ChatPanel } from "../pages/chat.page";
import { OpenAccountPage } from "../pages/open-account.page";

const accountsUrl = process.env.ACCOUNTS_URL ?? "http://localhost:3001";

interface Bank {
  /** Creates an account straight through the API and returns its id (test data setup). */
  createAccount(name: string, balanceDollars: number): Promise<string>;
}

interface Fixtures {
  openAccountPage: OpenAccountPage;
  accountPage: AccountPage;
  chat: ChatPanel;
  bank: Bank;
  /** Scenario state shared between steps. */
  world: { accountId?: string; otherId?: string };
}

export const test = base.extend<Fixtures>({
  openAccountPage: async ({ page }, use) => use(new OpenAccountPage(page)),
  accountPage: async ({ page }, use) => use(new AccountPage(page)),
  chat: async ({ page }, use) => use(new ChatPanel(page)),
  world: async ({}, use) => use({}),
  bank: async ({ request }, use) =>
    use({
      async createAccount(name, balanceDollars) {
        const res = await request.post(`${accountsUrl}/accounts`, { data: { name, type: "checking" } });
        const { id } = await res.json();
        if (balanceDollars > 0) {
          await request.post(`${accountsUrl}/accounts/${id}/deposits`, { data: { amountMinor: balanceDollars * 100 } });
        }
        return id as string;
      },
    }),
});

export { expect } from "@playwright/test";
