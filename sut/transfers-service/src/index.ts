import { httpAccountsClient } from "./accounts-client.ts";
import { buildApp } from "./app.ts";
import { connect } from "./db.ts";

const pool = await connect(process.env.DATABASE_URL ?? "postgres://bank:bank_local_pw@localhost:5432/bank");
const accounts = httpAccountsClient(process.env.ACCOUNTS_URL ?? "http://localhost:3001");
const app = buildApp(pool, accounts, process.env.ROUTE_PREFIX ?? "");
await app.listen({ port: Number(process.env.PORT ?? 3002), host: "0.0.0.0" });
