import pg from "pg";

export type Db = Pick<pg.Pool, "query">;

export async function connect(url: string): Promise<pg.Pool> {
  const pool = new pg.Pool({ connectionString: url, max: 10 });
  for (let attempt = 1; ; attempt++) {
    try {
      await pool.query(`CREATE TABLE IF NOT EXISTS accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance_minor BIGINT NOT NULL DEFAULT 0
      )`);
      return pool;
    } catch (err) {
      if (attempt >= 20) throw err;
      await new Promise((r) => setTimeout(r, 1000));
    }
  }
}
