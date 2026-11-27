import { randomUUID } from "node:crypto";
import Fastify, { type FastifyInstance } from "fastify";
import type { Db } from "./db.ts";

const ACCOUNT_TYPES = ["checking", "savings"];

interface Row {
  id: string;
  name: string;
  type: string;
  balance_minor: string;
}

export function toAccount(row: Row) {
  return { id: row.id, name: row.name, type: row.type, balanceMinor: Number(row.balance_minor) };
}

export function isPositiveInt(value: unknown): value is number {
  return typeof value === "number" && Number.isInteger(value) && value > 0;
}

export function buildApp(db: Db, prefix = ""): FastifyInstance {
  const app = Fastify({ logger: { level: process.env.LOG_LEVEL ?? "info" } });

  const health = async () => ({ status: "ok", service: "accounts-service" });
  app.get("/healthz", health);
  if (prefix) app.get(`${prefix}/healthz`, health);

  app.register(
    async (r) => {
      r.post("/accounts", async (req, reply) => {
        const { name, type } = (req.body ?? {}) as { name?: string; type?: string };
        if (!name || !type || !ACCOUNT_TYPES.includes(type)) {
          return reply.code(400).send({ error: "INVALID_REQUEST", message: "name and type (checking|savings) are required" });
        }
        const id = randomUUID();
        await db.query("INSERT INTO accounts (id, name, type) VALUES ($1, $2, $3)", [id, name, type]);
        return reply.code(201).send({ id, name, type, balanceMinor: 0 });
      });

      r.get("/accounts/:id", async (req, reply) => {
        const { id } = req.params as { id: string };
        const res = await db.query("SELECT * FROM accounts WHERE id = $1", [id]);
        if (res.rowCount === 0) return reply.code(404).send({ error: "ACCOUNT_NOT_FOUND" });
        return toAccount(res.rows[0]);
      });

      r.post("/accounts/:id/deposits", async (req, reply) => {
        const { id } = req.params as { id: string };
        const { amountMinor } = (req.body ?? {}) as { amountMinor?: unknown };
        if (!isPositiveInt(amountMinor)) {
          return reply.code(400).send({ error: "INVALID_REQUEST", message: "amountMinor must be a positive integer" });
        }
        const res = await db.query(
          "UPDATE accounts SET balance_minor = balance_minor + $1 WHERE id = $2 RETURNING *",
          [amountMinor, id],
        );
        if (res.rowCount === 0) return reply.code(404).send({ error: "ACCOUNT_NOT_FOUND" });
        return toAccount(res.rows[0]);
      });

      r.post("/accounts/:id/withdrawals", async (req, reply) => {
        const { id } = req.params as { id: string };
        const { amountMinor } = (req.body ?? {}) as { amountMinor?: unknown };
        if (!isPositiveInt(amountMinor)) {
          return reply.code(400).send({ error: "INVALID_REQUEST", message: "amountMinor must be a positive integer" });
        }
        const res = await db.query(
          "UPDATE accounts SET balance_minor = balance_minor - $1 WHERE id = $2 AND balance_minor >= $1 RETURNING *",
          [amountMinor, id],
        );
        if (res.rowCount === 0) {
          const exists = await db.query("SELECT 1 FROM accounts WHERE id = $1", [id]);
          if (exists.rowCount === 0) return reply.code(404).send({ error: "ACCOUNT_NOT_FOUND" });
          return reply.code(409).send({ error: "INSUFFICIENT_FUNDS" });
        }
        return toAccount(res.rows[0]);
      });
    },
    { prefix },
  );

  return app;
}
