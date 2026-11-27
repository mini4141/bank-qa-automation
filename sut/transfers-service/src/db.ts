import pg from "pg";

export type Db = Pick<pg.Pool, "query">;

export async function connect(url: string): Promise<pg.Pool> {
  const pool = new pg.Pool({ connectionString: url, max: 10 });
  for (let attempt = 1; ; attempt++) {
    try {
      await pool.query(`CREATE TABLE IF NOT EXISTS transfers (
        id TEXT PRIMARY KEY,
        from_id TEXT NOT NULL,
        to_id TEXT NOT NULL,
        amount_minor BIGINT NOT NULL,
        fee_minor BIGINT NOT NULL,
        idempotency_key TEXT UNIQUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
      )`);
      return pool;
    } catch (err) {
      if (attempt >= 20) throw err;
      await new Promise((r) => setTimeout(r, 1000));
    }
  }
}
