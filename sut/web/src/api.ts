export interface Account { id: string; name: string; type: string; balanceMinor: number }
export interface Transfer { id: string; fromId: string; toId: string; amountMinor: number; feeMinor: number; createdAt: string }
export interface ChatAnswer { answer: string; citations: { docId: string; title: string; url: string }[] }

async function call<T>(url: string, body?: unknown): Promise<T> {
  const res = await fetch(url, body === undefined ? undefined : {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.message ?? data.error ?? `HTTP ${res.status}`);
  return data as T;
}

export const api = {
  openAccount: (name: string, type: string) => call<Account>("/api/accounts/accounts", { name, type }),
  getAccount: (id: string) => call<Account>(`/api/accounts/accounts/${id}`),
  deposit: (id: string, amountMinor: number) => call<Account>(`/api/accounts/accounts/${id}/deposits`, { amountMinor }),
  transfer: (fromId: string, toId: string, amountMinor: number) =>
    call<Transfer>("/api/transfers/transfers", { fromId, toId, amountMinor }),
  listTransfers: (accountId: string) => call<Transfer[]>(`/api/transfers/transfers?accountId=${accountId}`),
  ask: (question: string) => call<ChatAnswer>("/api/chat/chat", { question }),
};

export const toMinor = (dollars: string) => Math.round(parseFloat(dollars) * 100);
export const money = (minor: number) => `$${(minor / 100).toFixed(2)}`;
