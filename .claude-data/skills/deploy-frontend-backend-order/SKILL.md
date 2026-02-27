---
name: deploy-frontend-backend-order
description: Guides correct deployment order for full-stack apps (backend first, then frontend). Use when deploying frontend and backend separately.
---

# Frontend + Backend Deployment Order

When frontend and backend are deployed separately, they need to know each other's URLs.

## The Problem

- Frontend needs backend API URL to make requests
- Backend URL is only known **after deployment**
- Solution: **Deploy backend first**

## Deployment Order

```
1. Deploy Backend → Get URL
2. Configure Frontend with backend URL
3. Deploy Frontend
```

## Step 1: Deploy Backend

Backend must enable CORS to allow cross-origin requests:

```python
# Python (FastAPI/Starlette)
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
```

```typescript
// JavaScript (Hono)
import { cors } from 'hono/cors'
app.use('*', cors())
```

Deploy and save the URL:

```bash
nxcode deploy --type fastapi --dir backend
# Returns: https://thr-xxx-my-api.workers.dev  ← Save this!
```

## Step 2: Configure Frontend

Frontend should use environment variable for API URL:

```javascript
// src/config.js or src/lib/api.js
const API_URL = import.meta.env.VITE_API_URL || '/api'

// Usage
fetch(`${API_URL}/users`)
```

Add backend URL to frontend's `wrangler.toml`:

```toml
name = "my-frontend"

[vars]
VITE_API_URL = "https://thr-xxx-my-api.workers.dev"
```

## Step 3: Deploy Frontend

```bash
cd frontend && npm run build
nxcode deploy --type static --dir dist
```

## Summary

| Order | Action | Note |
|-------|--------|------|
| 1st | Deploy backend | Enable CORS `["*"]`, get URL |
| 2nd | Update frontend config | Set `VITE_API_URL` to backend URL |
| 3rd | Deploy frontend | Build first, then deploy |

## Common Mistakes

- Deploying frontend first (won't know backend URL)
- Forgetting CORS on backend (browser blocks requests)
- Hardcoding `localhost` in frontend code
