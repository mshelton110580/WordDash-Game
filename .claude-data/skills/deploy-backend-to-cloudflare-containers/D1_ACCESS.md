# Accessing D1 Database from Containers

Containers access D1 **through the Worker proxy**, not directly.

## Step 1: Create D1 Database

```bash
nxcode d1 create my-database
# Note the database_id from output
```

## Step 2: Update wrangler.toml

```toml
[[d1_databases]]
binding = "DB"
database_name = "my-database"
database_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

## Step 3: Worker with D1 Proxy (src/index.js)

```javascript
import { Container, getRandom } from "@cloudflare/containers";

export class Backend extends Container {
  defaultPort = 8000;
  sleepAfter = "30m";
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // D1 proxy: SELECT queries
    if (url.pathname === "/internal/db/query") {
      try {
        const { sql, params = [] } = await request.json();
        const stmt = env.DB.prepare(sql);
        const result = params.length > 0
          ? await stmt.bind(...params).all()
          : await stmt.all();
        return Response.json({ success: true, results: result.results });
      } catch (error) {
        return Response.json({ success: false, error: error.message }, { status: 500 });
      }
    }

    // D1 proxy: INSERT/UPDATE/DELETE
    if (url.pathname === "/internal/db/run") {
      try {
        const { sql, params = [] } = await request.json();
        const stmt = env.DB.prepare(sql);
        const result = params.length > 0
          ? await stmt.bind(...params).run()
          : await stmt.run();
        return Response.json({ success: true, meta: result.meta });
      } catch (error) {
        return Response.json({ success: false, error: error.message }, { status: 500 });
      }
    }

    // KV proxy
    if (url.pathname === "/internal/kv/get") {
      const { key } = await request.json();
      const value = await env.KV.get(key);
      return Response.json({ value });
    }

    if (url.pathname === "/internal/kv/put") {
      const { key, value } = await request.json();
      await env.KV.put(key, value);
      return Response.json({ success: true });
    }

    // R2 proxy
    if (url.pathname === "/internal/r2/get") {
      const { key } = await request.json();
      const object = await env.BUCKET.get(key);
      if (!object) return Response.json({ exists: false });
      return new Response(object.body);
    }

    // Route /api/* to container
    if (url.pathname.startsWith("/api")) {
      const container = await getRandom(env.BACKEND, 1);
      await container.start();
      return container.fetch(request);
    }

    if (env.ASSETS) return env.ASSETS.fetch(request);
    return new Response("Not found", { status: 404 });
  },
};

export { Backend };
```

## Step 4: Python D1 Client (db.py)

Container calls Worker's internal endpoints via the same origin:

```python
import httpx

async def db_query(sql: str, params: list = None):
    """Execute SELECT query and return results."""
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            "/internal/db/query",
            json={"sql": sql, "params": params or []},
            timeout=30.0
        )
        data = resp.json()
        if not data.get("success"):
            raise Exception(data.get("error", "Database query failed"))
        return data.get("results", [])

async def db_run(sql: str, params: list = None):
    """Execute INSERT/UPDATE/DELETE and return metadata."""
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            "/internal/db/run",
            json={"sql": sql, "params": params or []},
            timeout=30.0
        )
        data = resp.json()
        if not data.get("success"):
            raise Exception(data.get("error", "Database operation failed"))
        return data.get("meta", {})
```

## Step 5: Using D1 in FastAPI (app.py)

```python
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from db import db_query, db_run

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def init_db():
    await db_run("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            name TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)

@app.get("/api/users")
async def get_users():
    users = await db_query("SELECT * FROM users ORDER BY created_at DESC")
    return {"users": users}

@app.post("/api/users")
async def create_user(data: dict):
    email = data.get("email")
    name = data.get("name", "")
    if not email:
        raise HTTPException(400, "Email required")
    await db_run("INSERT INTO users (email, name) VALUES (?, ?)", [email, name])
    return {"success": True, "email": email}
```

Add `httpx` to requirements.txt:

```txt
fastapi==0.115.0
uvicorn==0.32.0
httpx==0.27.0
```
