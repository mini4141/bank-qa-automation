export class AccountsUnavailableError extends Error {}

export class AccountsError extends Error {
  status: number;
  code: string;
  constructor(status: number, code: string) {
    super(code);
    this.status = status;
    this.code = code;
  }
}

export interface AccountsClient {
  withdraw(accountId: string, amountMinor: number): Promise<void>;
  deposit(accountId: string, amountMinor: number): Promise<void>;
}

export function httpAccountsClient(baseUrl: string): AccountsClient {
  async function post(path: string, amountMinor: number) {
    let res: Response;
    try {
      res = await fetch(`${baseUrl}${path}`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ amountMinor }),
        signal: AbortSignal.timeout(3000),
      });
    } catch {
      throw new AccountsUnavailableError("accounts-service is unreachable");
    }
    if (res.status >= 500) throw new AccountsUnavailableError(`accounts-service returned ${res.status}`);
    if (!res.ok) {
      const body = (await res.json().catch(() => ({}))) as { error?: string };
      throw new AccountsError(res.status, body.error ?? "ACCOUNTS_ERROR");
    }
  }
  return {
    withdraw: (id, amount) => post(`/accounts/${id}/withdrawals`, amount),
    deposit: (id, amount) => post(`/accounts/${id}/deposits`, amount),
  };
}
