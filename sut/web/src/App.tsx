import { useCallback, useEffect, useState, type FormEvent } from "react";
import { api, money, toMinor, type Account, type ChatAnswer, type Transfer } from "./api";

function useHashRoute(): string {
  const [hash, setHash] = useState(window.location.hash);
  useEffect(() => {
    const onChange = () => setHash(window.location.hash);
    window.addEventListener("hashchange", onChange);
    return () => window.removeEventListener("hashchange", onChange);
  }, []);
  return hash;
}

function OpenAccount() {
  const [name, setName] = useState("");
  const [type, setType] = useState("savings");
  const [error, setError] = useState("");

  async function submit(e: FormEvent) {
    e.preventDefault();
    try {
      const account = await api.openAccount(name, type);
      window.location.hash = `#/accounts/${account.id}`;
    } catch (err) {
      setError((err as Error).message);
    }
  }

  return (
    <form className="card" onSubmit={submit} data-testid="open-account-form">
      <h2>Open an account</h2>
      <label>Full name<input data-testid="account-name-input" value={name} onChange={(e) => setName(e.target.value)} required /></label>
      <label>Account type
        <select data-testid="account-type-select" value={type} onChange={(e) => setType(e.target.value)}>
          <option value="savings">Savings</option>
          <option value="checking">Checking</option>
        </select>
      </label>
      <button data-testid="open-account-submit" type="submit">Open account</button>
      {error && <p className="error" data-testid="open-account-error">{error}</p>}
    </form>
  );
}

function AccountPage({ id }: { id: string }) {
  const [account, setAccount] = useState<Account | null>(null);
  const [transfers, setTransfers] = useState<Transfer[]>([]);
  const [deposit, setDeposit] = useState("");
  const [toId, setToId] = useState("");
  const [amount, setAmount] = useState("");
  const [result, setResult] = useState("");
  const [error, setError] = useState("");

  const refresh = useCallback(async () => {
    setAccount(await api.getAccount(id));
    setTransfers(await api.listTransfers(id));
  }, [id]);

  useEffect(() => { refresh().catch((err) => setError(err.message)); }, [refresh]);

  async function submitDeposit(e: FormEvent) {
    e.preventDefault();
    setError("");
    try {
      await api.deposit(id, toMinor(deposit));
      setDeposit("");
      await refresh();
    } catch (err) {
      setError((err as Error).message);
    }
  }

  async function submitTransfer(e: FormEvent) {
    e.preventDefault();
    setError("");
    setResult("");
    try {
      const t = await api.transfer(id, toId, toMinor(amount));
      setResult(`Transfer sent. Fee ${money(t.feeMinor)}`);
      setAmount("");
      await refresh();
    } catch (err) {
      setError((err as Error).message);
    }
  }

  if (!account) return <p>{error || "Loading..."}</p>;

  return (
    <>
      <section className="card" data-testid="account-summary">
        <h2 data-testid="account-name">{account.name}</h2>
        <p>Account ID <code data-testid="account-id">{account.id}</code></p>
        <p className="balance" data-testid="account-balance">{money(account.balanceMinor)}</p>
        <p className="muted">{account.type} account</p>
      </section>
      <form className="card" onSubmit={submitDeposit}>
        <h3>Deposit</h3>
        <label>Amount ($)<input data-testid="deposit-amount" inputMode="decimal" value={deposit} onChange={(e) => setDeposit(e.target.value)} required /></label>
        <button data-testid="deposit-submit" type="submit">Deposit</button>
      </form>
      <form className="card" onSubmit={submitTransfer}>
        <h3>Transfer</h3>
        <label>To account ID<input data-testid="transfer-to" value={toId} onChange={(e) => setToId(e.target.value)} required /></label>
        <label>Amount ($)<input data-testid="transfer-amount" inputMode="decimal" value={amount} onChange={(e) => setAmount(e.target.value)} required /></label>
        <button data-testid="transfer-submit" type="submit">Send transfer</button>
        {result && <p className="ok" data-testid="transfer-result">{result}</p>}
      </form>
      {error && <p className="error" data-testid="page-error">{error}</p>}
      <section className="card">
        <h3>Transactions</h3>
        <ul className="transactions" data-testid="transaction-list">
          {transfers.map((t) => (
            <li key={t.id} data-testid="transaction-row">
              {t.fromId === id ? "Sent" : "Received"} {money(t.amountMinor)}
              {t.fromId === id && <span className="muted"> (fee {money(t.feeMinor)})</span>}
            </li>
          ))}
          {transfers.length === 0 && <li className="muted">No transactions yet</li>}
        </ul>
      </section>
    </>
  );
}

function ChatPanel() {
  const [question, setQuestion] = useState("");
  const [reply, setReply] = useState<ChatAnswer | null>(null);
  const [error, setError] = useState("");

  async function ask(e: FormEvent) {
    e.preventDefault();
    setError("");
    try {
      setReply(await api.ask(question));
    } catch (err) {
      setError((err as Error).message);
    }
  }

  return (
    <form className="card" onSubmit={ask} data-testid="chat-panel">
      <h3>Ask our assistant</h3>
      <label>Your question<input data-testid="chat-input" value={question} onChange={(e) => setQuestion(e.target.value)} required /></label>
      <button data-testid="chat-send" type="submit">Ask</button>
      {reply && (
        <div data-testid="chat-answer">
          <p>{reply.answer}</p>
          {reply.citations.map((c) => (
            <a key={c.docId} data-testid="citation-link" href={`/api/chat${c.url}`} target="_blank" rel="noreferrer">
              Source: {c.title}
            </a>
          ))}
        </div>
      )}
      {error && <p className="error">{error}</p>}
    </form>
  );
}

export function App() {
  const hash = useHashRoute();
  const match = hash.match(/^#\/accounts\/(.+)$/);
  return (
    <main>
      <header><a href="#/" data-testid="home-link">Northwind Bank</a></header>
      {match ? <AccountPage key={match[1]} id={match[1]} /> : <OpenAccount />}
      <ChatPanel />
    </main>
  );
}
