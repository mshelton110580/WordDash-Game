---
name: frontend-backend-cors-fix
description: Configures dev server proxy to fix CORS issues in full-stack projects. Use when frontend calls backend API and gets CORS errors.
---

# 前后端项目跨域问题解决方案（必读）

## ⚠️ CRITICAL: Never Use localhost URLs in Frontend Code

**NEVER write code like this in frontend:**
```javascript
// ❌ WRONG - Will cause CORS error and doesn't work in Docker
fetch('http://localhost:8000/api/signup', ...)
```

**ALWAYS use relative paths:**
```javascript
// ✅ CORRECT - Works with proxy, no CORS issues
fetch('/api/signup', ...)
```

**Why?**
1. `localhost:8000` is a different origin → CORS blocks it
2. In Docker containers, `localhost` refers to the container itself, not the host
3. Users cannot access `localhost:8000` from their browser (it's inside Docker)

## The Problem

When frontend calls backend API using absolute URLs like `fetch('http://localhost:8000/api/...')`, the browser blocks the request due to **CORS (Cross-Origin Resource Sharing)** policy.

This happens because:
- Frontend is served from `thr-xxx.localhost:8080` (via OpenResty)
- Backend is on `localhost:8000` (different origin inside Docker)
- Browser blocks cross-origin requests by default
- **Even if CORS is configured, the URL is wrong because localhost inside Docker ≠ localhost for user**

## The Solution

1. Configure the frontend dev server to **proxy** `/api` requests to the backend
2. **Use relative paths in ALL frontend API calls**

This makes API calls same-origin, avoiding CORS entirely.

## When to Apply

**Always** configure proxy when:
- Project has separate frontend and backend
- Frontend makes API calls to backend

## What to Do (Both Steps Required!)

1. Configure frontend dev server to proxy `/api/*` to backend port (e.g., `localhost:8000`)
2. **MUST change frontend API calls to use relative paths**: `fetch('/api/...')`

**If you skip step 2, CORS errors will occur!**

## Framework-Specific Proxy Configuration

### Next.js (next.config.js or next.config.ts)

```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: 'http://localhost:8000/api/:path*',
      },
    ];
  },
};

module.exports = nextConfig;
```

### Vite (vite.config.ts)

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
});
```

### Frontend API Calls

After configuring proxy, use **relative paths**:

```javascript
// ✅ Correct - uses proxy
fetch('/api/signup', { method: 'POST', body: JSON.stringify({ email }) })

// ❌ Wrong - causes CORS error
fetch('http://localhost:8000/api/signup', { method: 'POST', ... })
```

## Backend CORS (Alternative)

If you cannot configure frontend proxy, add CORS to backend:

### FastAPI

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Or specific origin like "http://localhost:3000"
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

**Note**: Frontend proxy is preferred because it works in both dev and production. Backend CORS may need different config for production.

## Request Flow

```
Browser (thr-xxx.localhost:8080)
    ↓ fetch('/api/users')
OpenResty (port 8080)
    ↓ proxies to frontend
Frontend Dev Server (port 5173)
    ↓ proxy config: /api/* -> localhost:8000
Backend (port 8000)
    ↓ returns JSON
Response flows back
```

**Key**: Browser sees all requests going to same origin, no CORS!

## ⚠️ Don't Forget: Register Preview

After starting the dev server, you MUST register it for preview:

```bash
# Start frontend dev server (nohup prevents termination when shell exits)
nohup npm run dev > /tmp/dev-server.log 2>&1 &
sleep 3

# MUST call this for preview to work!
nxcode report-preview --port 5173
```

**Without `nxcode report-preview`, the user cannot see the preview!**

## ⚠️ Never Tell Users to Access localhost

**NEVER tell users to visit URLs like:**
- `http://localhost:8000/health`
- `http://localhost:3000`
- Any `localhost:*` URL

**Why?**
- Code runs inside Docker containers
- `localhost` inside Docker ≠ `localhost` on user's machine
- Users can ONLY access the app via the preview URL (`thr-xxx.localhost:8080`)

**Instead, say:**
- "Please refresh the preview window"
- "The app should now be working in the preview"
