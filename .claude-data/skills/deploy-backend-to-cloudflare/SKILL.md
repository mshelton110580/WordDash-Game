---
name: deploy-backend-to-cloudflare
description: Deploys Hono/Node.js backend API to Cloudflare Workers with D1/KV/R2 bindings. Use when deploying backend or API services to Workers.
---

# Deploy Backend to Cloudflare Workers

## Overview

When deploying backend APIs to Cloudflare Workers, migrate local resources to cloud equivalents:

| Local Resource | Cloudflare Equivalent | Migration Command |
|----------------|----------------------|-------------------|
| SQLite | D1 | `nxcode d1 create <name>` |
| File storage | R2 | `nxcode r2 create <name>` |
| Environment variables | Secrets | `nxcode secret set <worker> KEY value` |
| Cache/Session | KV | `nxcode kv create <name>` |

## Choosing the Right Deployment Method

| Backend Type | Recommended Method | Skill to Use |
|--------------|-------------------|--------------|
| **Hono/Node.js API** | **Workers** | **This skill** |
| **FastAPI** | **Containers** | `deploy-backend-to-cloudflare-containers` |
| Django/Flask | Containers | `deploy-backend-to-cloudflare-containers` |

**If you're deploying FastAPI, STOP HERE** and use the `deploy-backend-to-cloudflare-containers` skill instead. FastAPI almost always exceeds Python Workers' 1000ms CPU startup limit.

---

## Hono Deployment (Primary Use Case)

**Hono is the recommended backend framework for Workers.**

### Development vs Production Database

| Environment | Database | API |
|-------------|----------|-----|
| **Development** | better-sqlite3 | MockD1Database (mimics D1 API) |
| **Production** | Cloudflare D1 | Native D1 API |

Your code uses the same API in both environments via the abstraction layer in `src/lib/db.ts`.

### wrangler.toml

```toml
name = "my-api"
main = "src/index.ts"
compatibility_date = "2024-12-01"

[[d1_databases]]
binding = "DB"
database_name = "nxcode-xxx-my-db"
database_id = "xxx"

[[kv_namespaces]]
binding = "CACHE"
id = "xxx"  # Get from: nxcode kv list

[[r2_buckets]]
binding = "STORAGE"
bucket_name = "nxcode-xxx-uploads"
```

### Hono Code with CORS

```typescript
import { Hono } from 'hono'
import { cors } from 'hono/cors'

type Bindings = { DB: D1Database }

const app = new Hono<{ Bindings: Bindings }>()

app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}))

app.post('/api/signup', async (c) => {
  const { email } = await c.req.json()
  const result = await c.env.DB.prepare(
    'INSERT INTO leads (email) VALUES (?) RETURNING *'
  ).bind(email).first()
  return c.json({ success: true, lead: result })
})

export default app
```

### Deploy

```bash
nxcode deploy --type hono --dir backend
```

## Resource Commands

### D1 (Database)

```bash
nxcode d1 create <name>              # Create database
nxcode d1 list                       # List all databases (shows names and IDs)
nxcode d1 execute <name> "SQL"       # Execute SQL statement
nxcode d1 query <name> "SELECT..."   # Query data
nxcode d1 delete <name>              # Delete database
```

### KV (Key-Value Store)

```bash
nxcode kv create <name>              # Create KV namespace
nxcode kv list                       # List all KV namespaces
nxcode kv put <name> <key> <value>   # Write data
nxcode kv get <name> <key>           # Read data
nxcode kv delete <name>              # Delete namespace
```

### R2 (Object Storage)

```bash
nxcode r2 create <name>              # Create bucket
nxcode r2 list                       # List all buckets
nxcode r2 put <name> <key> <file>    # Upload file
nxcode r2 get <name> <key>           # Download file
nxcode r2 delete <name>              # Delete bucket
```

### Secrets (Environment Variables)

```bash
nxcode secret set <worker> <KEY> <value>   # Set secret
nxcode secret list <worker>                 # List secrets
nxcode secret delete <worker> <KEY>         # Delete secret
```

## Resource Naming

All resource names are **automatically prefixed** with thread ID for isolation:

| Command | You Input | Actually Created |
|---------|-----------|------------------|
| `nxcode d1 create my-db` | `my-db` | `nxcode-thr_3561-my-db` |
| `nxcode kv create cache` | `cache` | `nxcode-thr_3561-cache` |
| `nxcode r2 create uploads` | `uploads` | `nxcode-thr_3561-uploads` |

Use `nxcode d1 list`, `nxcode kv list`, etc. to get the actual names and IDs for wrangler.toml.

## Storage & Database Migration

For migrating local resources to Cloudflare equivalents, see [MIGRATION.md](MIGRATION.md).

## Pre-Deployment Checklist

| Check | Detection | Migration Target |
|-------|-----------|-----------------|
| SQLite | `grep -r "sqlite"` | D1 |
| File system | `grep -r "fs\." "writeFile"` | R2 |
| Environment variables | `.env` file exists | Secrets/Vars |
| Redis | `grep -r "redis" "ioredis"` | KV/Durable Objects |

## Important Notes

1. **Create resources first**: Run `nxcode d1/kv/r2 create` before adding bindings to wrangler.toml
2. **Get IDs from list commands**: Use `nxcode d1 list` to get actual database_name and database_id
3. **Secrets match worker name**: `nxcode secret` auto-prefixes to match deployed worker names
4. **Update frontend API URLs**: After deploying backend, update frontend to use the new Workers URL

## Troubleshooting

### Python Worker CPU Limit Error

If you see: `Python Worker startup exceeded CPU limit 1299<=1000`

**Solution**: Use the `deploy-backend-to-cloudflare-containers` skill instead.

### CORS Errors

Ensure CORS middleware is added:
- Hono: `app.use('*', cors({ origin: '*' }))`

### General Issues

1. Check wrangler.toml exists and has correct bindings
2. Verify D1/KV/R2 resources were created before deployment
3. Check `nxcode d1 list` for correct database_id
4. Ensure secrets are set after deployment (not before)

## DO NOT

- **DO NOT** deploy FastAPI to Workers — use `deploy-backend-to-cloudflare-containers`
- **DO NOT** add bindings to wrangler.toml before creating resources
- **DO NOT** use local file paths or SQLite in production code
