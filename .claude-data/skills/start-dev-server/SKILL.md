---
name: start-dev-server
description: Starts dev server and registers it for live preview. Use when user asks to "run", "start", "preview", or "show me" the app.
---

# Start Dev Server

Start the dev server and register it for live preview.

## ⚠️ CRITICAL: Two Steps Required

Starting a dev server requires **TWO steps**:

1. **Start the server** (npm run dev)
2. **Register preview** (nxcode report-preview) ← **DON'T FORGET THIS!**

**If you skip step 2, the user cannot see the preview!**

## Complete Example

```bash
# Step 1: Start dev server in background (nohup prevents termination when shell exits)
nohup npm run dev > /tmp/dev-server.log 2>&1 &

# Wait for server to be ready
sleep 3

# Step 2: MUST register preview for user to see it
nxcode report-preview --port 3000
```

## Common Ports by Framework

| Framework | Port | Command |
|-----------|------|---------|
| Next.js | 3000 | `nxcode report-preview --port 3000` |
| Vite/React | 5173 | `nxcode report-preview --port 5173` |
| Astro | 4321 | `nxcode report-preview --port 4321` |
| Hono (backend) | 3001 | `nxcode report-preview --port 3001` |
| FastAPI (backend) | 8000 | `nxcode report-preview --port 8000` |

## Checklist Before Finishing

- [ ] Dev server started with `nohup ... &` (background, survives shell exit)
- [ ] Waited for server ready (`sleep 3`)
- [ ] **Called `nxcode report-preview --port <PORT>`** ← Most important!

## Notes

- Bind to `0.0.0.0` for container access (e.g., `npm run dev -- --host 0.0.0.0`)
- The `--framework` parameter is optional (defaults to "vite")

## Hono Backend Templates

Hono templates have **two development modes**:

### Mode 1: Node.js Dev Server (Default - Recommended)

```bash
nohup npm run dev > /tmp/dev-server.log 2>&1 &
sleep 3
nxcode report-preview --port 3001
```

**Uses**: tsx + dev-server.ts with better-sqlite3
**Advantages**:
- ✅ Works in Alpine containers (no glibc dependency)
- ✅ Auto-initializes database from schema.sql
- ✅ Supports --auth, --ai, --payment modules
- ✅ Fast startup

**Database**: Uses better-sqlite3 with MockD1Database adapter that mimics Cloudflare D1 API.

### Mode 2: Wrangler Dev (Optional)

```bash
nohup npm run dev:wrangler > /tmp/dev-server.log 2>&1 &
sleep 3
nxcode report-preview --port 3001
```

**Uses**: wrangler dev (full Cloudflare Workers emulation)
**Limitations**:
- ❌ Requires glibc (not compatible with Alpine)
- ⚠️ Only use if you need full Workers environment testing

**Most users should use Mode 1 (npm run dev).**

## FastAPI Backend Templates

```bash
cd backend
nohup uvicorn src.main:app --reload --host 0.0.0.0 --port 8000 > /tmp/dev-server.log 2>&1 &
sleep 3
nxcode report-preview --port 8000
```

FastAPI uses standard sqlite3 in both development and production (Cloudflare Containers), so no special dev server needed.

## Frontend + Backend Projects

If project has both frontend and backend, you **MUST configure frontend dev server proxy** to avoid CORS errors when calling backend API.

See skill: `frontend-backend-cors-fix`
