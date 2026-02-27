---
name: deploy-backend-to-cloudflare-containers
description: Deploys FastAPI/Python backend to Cloudflare Containers with full Docker runtime. Use when Python Workers exceed CPU limits or when deploying FastAPI, Django, or Flask backends.
---

# Deploy Backend to Cloudflare Containers

**FastAPI projects should use this skill directly (not `deploy-backend-to-cloudflare`).**

> **CRITICAL LIMITATIONS**
>
> 1. **Backend Only**: Containers are for **backend/API only**. **NEVER use Containers for frontend** — use `deploy-frontend-to-cloudflare` skill instead.
> 2. **Architecture**: Containers only support `linux/amd64`. Always use `FROM --platform=linux/amd64` in Dockerfile.
> 3. **No Persistent Storage**: Local files are lost on redeploy. Use **D1** for database, **R2** for files.
> 4. **D1 is SQLite-based**: PostgreSQL syntax does NOT work! See [D1_SCHEMA.md](D1_SCHEMA.md).
> 5. **First Request Latency**: Container startup takes 10-30 seconds on first request after idle. This is normal.

## When to Use Containers

- **FastAPI** — almost always exceeds Python Workers' CPU limit
- **Django, Flask** — heavy frameworks need full runtime
- Projects needing **pip packages** or **large memory**

**DO NOT use Containers for frontend** (Next.js, React, Vue) — use `deploy-frontend-to-cloudflare` skill.

**Note**: Containers require **Workers Paid plan** ($5/month).

## Quick Start

### Project Structure

```
backend/
├── Dockerfile            # Python container image
├── wrangler.toml         # Cloudflare config
├── package.json          # REQUIRED: @cloudflare/containers dependency
├── src/
│   └── index.js          # Worker router (must export Container class)
├── app.py                # FastAPI app
└── requirements.txt      # Python dependencies
```

### Step 1: Create Dockerfile

```dockerfile
FROM --platform=linux/amd64 python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Step 2: Create requirements.txt

```txt
fastapi==0.115.0
uvicorn==0.32.0
```

### Step 3: Create FastAPI App (app.py)

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Hello from Cloudflare Containers"}

@app.get("/api/health")
async def health():
    return {"status": "healthy"}
```

### Step 4: Create package.json

**IMPORTANT**: Must include `@cloudflare/containers` dependency.

```json
{
  "name": "my-backend",
  "type": "module",
  "dependencies": {
    "@cloudflare/containers": "^0.1.0"
  }
}
```

### Step 5: Create Worker Router (src/index.js)

```javascript
import { Container, getRandom } from "@cloudflare/containers";

export class Backend extends Container {
  defaultPort = 8000;      // Must match Dockerfile EXPOSE
  sleepAfter = "10m";      // Sleep after 10 minutes of inactivity
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname.startsWith("/api")) {
      const container = await getRandom(env.BACKEND, 3);
      await container.start();
      return container.fetch(request);
    }

    if (env.ASSETS) {
      return env.ASSETS.fetch(request);
    }

    return new Response("Not found", { status: 404 });
  },
};
```

### Step 6: Create wrangler.toml

```toml
name = "my-backend"
main = "src/index.js"
compatibility_date = "2024-12-01"

[observability]
enabled = true

[[containers]]
class_name = "Backend"
image = "./Dockerfile"
max_instances = 3
instance_type = "basic"    # 1/4 vCPU, 1GB RAM

[[durable_objects.bindings]]
class_name = "Backend"
name = "BACKEND"

[[migrations]]
new_sqlite_classes = ["Backend"]
tag = "v1"
```

### Step 7: Deploy

```bash
nxcode deploy --type container --dir backend
```

### Step 8: Verify

Container startup takes 10-30 seconds on first request. This is normal!

```bash
sleep 15
curl https://your-worker.workers.dev/api/health
```

## Instance Types

| Type | vCPU | Memory | Disk |
|------|------|--------|------|
| lite | 1/16 | 256 MB | 2 GB |
| basic | 1/4 | 1 GB | 4 GB |
| standard-1 | 1/2 | 4 GB | 8 GB |
| standard-2 | 1 | 6 GB | 12 GB |

## Accessing D1 Database

Containers access D1 **through the Worker proxy**, not directly. See [D1_ACCESS.md](D1_ACCESS.md) for the complete Worker proxy pattern with Python client code.

## Accessing KV/R2

Use the same Worker proxy pattern as D1. See [D1_ACCESS.md](D1_ACCESS.md) for KV/R2 proxy endpoints.

## Environment Variables

Pass custom vars in the Container class:

```javascript
class Backend extends Container {
  envVars = {
    CUSTOM_VAR: "value",
    API_KEY: this.env.API_KEY,  // From Worker secrets
  };
}
```

Set Worker secrets:

```bash
nxcode secret set my-backend API_KEY your-api-key-value
```

## Full-Stack Deployment

See [FULLSTACK.md](FULLSTACK.md) for the recommended frontend + container backend pattern.

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common errors and fixes.

## DO NOT

- **DO NOT** use Containers for frontend (Next.js, React, Vue)
- **DO NOT** use PostgreSQL syntax with D1 — it's SQLite-based
- **DO NOT** use native Node.js modules (sqlite3, bcrypt, sharp) — they crash in containers
- **DO NOT** use local file storage — use D1 for data, R2 for files
