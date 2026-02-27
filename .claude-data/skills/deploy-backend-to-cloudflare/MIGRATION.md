# Storage & Database Migration

## SQLite → D1 Migration

**Step 1:** Detect SQLite usage
```bash
grep -r "sqlite" --include="*.py" --include="*.ts" --include="*.js" .
```

**Step 2:** Export existing schema
```bash
sqlite3 database.db ".schema" > schema.sql
```

**Step 3:** Create D1 and import schema
```bash
nxcode d1 create my-database
nxcode d1 execute my-database --file schema.sql
```

**Step 4:** Rewrite code

JavaScript (better-sqlite3 → D1):
```typescript
// Before: better-sqlite3
import Database from 'better-sqlite3';
const db = new Database('database.db');

// After: D1 binding
export default {
  async fetch(request, env) {
    const result = await env.DB.prepare("SELECT * FROM users").all();
    return Response.json(result);
  }
}
```

## File Storage → R2

```typescript
// Before: fs.writeFile
fs.writeFileSync("uploads/file.png", buffer);

// After: R2
await env.BUCKET.put("uploads/file.png", buffer);

// Reading
const object = await env.BUCKET.get("uploads/file.png");
const data = await object.arrayBuffer();
```

## Environment Variables → Secrets

```bash
# Set secrets after deployment
nxcode secret set my-api API_KEY "sk-xxx"

# Non-sensitive vars go in wrangler.toml
[vars]
API_URL = "https://api.example.com"
```

Access in code via `env.API_KEY`.

## Redis/Cache → KV

| Original | Migration Target | Use Case |
|----------|-----------------|----------|
| Redis (cache) | KV | Simple key-value cache |
| Redis (session) | KV + short TTL | Session storage |
| Redis (counter) | Durable Objects | Atomic operations |
| Redis (queue) | Queues | Message queue |
