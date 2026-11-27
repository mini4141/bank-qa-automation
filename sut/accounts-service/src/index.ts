import { buildApp } from "./app.ts";
import { connect } from "./db.ts";

const pool = await connect(process.env.DATABASE_URL ?? "postgres://bank:bank_local_pw@localhost:5432/bank");
const app = buildApp(pool, process.env.ROUTE_PREFIX ?? "");
await app.listen({ port: Number(process.env.PORT ?? 3001), host: "0.0.0.0" });
