# D1/SQLite Schema Requirements

**D1 is SQLite-based, NOT PostgreSQL!** The following PostgreSQL features will cause errors:

| PostgreSQL | D1/SQLite Equivalent |
|------------|---------------------|
| `UUID` | `TEXT` (generate UUID in code with `db.generate_uuid()`) |
| `SERIAL` | `INTEGER PRIMARY KEY AUTOINCREMENT` |
| `TIMESTAMPTZ` | `TEXT` (ISO8601 format, use `db.now_iso()` in code) |
| `gen_random_uuid()` | Generate in code: `db.generate_uuid()` |
| `JSONB` | `TEXT` (store/parse JSON in code) |
| `NUMERIC(p,s)` | `REAL` or `INTEGER` |
| `BOOLEAN` | `INTEGER` (0/1) |
| `DEFAULT datetime('now')` | Not supported — set in application code |
| `CREATE EXTENSION` | Not supported — remove these lines |
| `INTERVAL` | Not supported — compute in application |

## Example D1-Compatible Schema

```sql
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TEXT,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    is_published INTEGER DEFAULT 0,
    metadata TEXT,
    created_at TEXT
);
```

## PostgreSQL Schema That Will FAIL

```sql
-- These will crash the container!
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```
