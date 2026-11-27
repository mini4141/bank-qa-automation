import { randomUUID } from "node:crypto";
import Fastify, { type FastifyInstance } from "fastify";
import { AccountsError, AccountsUnavailableError, type AccountsClient } from "./accounts-client.ts";
import type { Db } from "./db.ts";
import { computeFee } from "./fee.ts";

interface Row {
  id: string;
  from_id: string;
  to_id: string;
  amount_minor: string;
  fee_minor: string;
  idempotency_key: string | null;
  created_at: Date;
}

export function toTransfer(row: Row) {
  return {
    id: row.id,
    fromId: row.from_id,
    toId: row.to_id,
    amountMinor: Number(row.amount_minor),
    feeMinor: Number(row.fee_minor),
    idempotencyKey: row.idempotency_key,
    createdAt: row.created_at,
  };
}

export function buildApp(db: Db, accounts: AccountsClient, prefix = ""): FastifyInstance {
  const app = Fastify({ logger: { level: process.env.LOG_LEVEL ?? "info" } });

  const health = async () => ({ status: "ok", service: "transfers-service" });
  app.get("/healthz", health);
  if (prefix) app.get(`${prefix}/healthz`, health);

  app.register(
    async (r) => {
      r.post("/transfers", async (req, reply) => {
        const { fromId, toId, amountMinor } = (req.body ?? {}) as { fromId?: string; toId?: string; amountMinor?: number };
        const key = (req.headers["idempotency-key"] as string | undefined) ?? null;
        if (!fromId || !toId || fromId === toId || !Number.isInteger(amountMinor) || (amountMinor as number) <= 0) {
          return reply.code(400).send({ error: "INVALID_REQUEST", message: "fromId, toId (different) and positive integer amountMinor are required" });
        }
        if (key) {
          const prior = await db.query("SELECT * FROM transfers WHERE idempotency_key = $1", [key]);
          if (prior.rowCount) return reply.code(200).send(toTransfer(prior.rows[0]));
        }
        const amount = amountMinor as number;
        const fee = computeFee(amount);
        try {
          await accounts.withdraw(fromId, amount + fee);
          await accounts.deposit(toId, amount);
        } catch (err) {
          if (err instanceof AccountsUnavailableError) {
            return reply.code(503).send({ error: "ACCOUNTS_UNAVAILABLE", message: "accounts service is unavailable, try again later" });
          }
          if (err instanceof AccountsError) return reply.code(err.status).send({ error: err.code });
          throw err;
        }
        const res = await db.query(
          "INSERT INTO transfers (id, from_id, to_id, amount_minor, fee_minor, idempotency_key) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *",
          [randomUUID(), fromId, toId, amount, fee, key],
        );
        return reply.code(201).send(toTransfer(res.rows[0]));
      });

      r.get("/transfers", async (req, reply) => {
        const { accountId } = req.query as { accountId?: string };
        if (!accountId) return reply.code(400).send({ error: "INVALID_REQUEST", message: "accountId is required" });
        const res = await db.query(
          "SELECT * FROM transfers WHERE from_id = $1 OR to_id = $1 ORDER BY created_at DESC",
          [accountId],
        );
        return res.rows.map(toTransfer);
      });
    },
    { prefix },
  );

  return app;
}
