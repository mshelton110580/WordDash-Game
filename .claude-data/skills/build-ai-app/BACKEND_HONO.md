# Backend AI: Hono/TypeScript (Cloudflare Workers)

## Code That Works in Both Dev and Production

The key: use `THREAD_ID` (dev) or `NXCODE_APP_ID` (production) to authenticate.

**wrangler.toml** — add `NXCODE_APP_ID` as a variable placeholder:

```toml
name = "my-api"
main = "src/index.ts"
compatibility_date = "2024-12-01"

[vars]
# Placeholder — nxcode deploy will set this automatically
# In dev, THREAD_ID env var is used instead
NXCODE_APP_ID = ""
```

**src/index.ts** — universal code:

```typescript
import { Hono } from 'hono';
import { cors } from 'hono/cors';

type Bindings = {
  NXCODE_APP_ID?: string;  // Set after deployment
  DB?: D1Database;
};

const app = new Hono<{ Bindings: Bindings }>();

app.use('*', cors({ origin: '*' }));

const AI_ENDPOINT = 'https://studio-api.nxcode.io/api/ai-gateway';

app.post('/api/chat', async (c) => {
  const { message } = await c.req.json();

  // Build auth headers — works in both dev and production
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  const appId = c.env.NXCODE_APP_ID;
  if (appId) {
    // Production: deployed to Cloudflare Workers
    headers['X-App-Id'] = appId;
    // Forward user auth if present (for user-pays mode)
    const userAuth = c.req.header('Authorization');
    if (userAuth) headers['Authorization'] = userAuth;
  } else {
    // Development: running in Nxcode workspace container
    headers['X-Workspace-Id'] = process.env.THREAD_ID || '';
    headers['X-Session-Token'] = c.req.header('X-Session-Token') || '';
  }

  const response = await fetch(
    `${AI_ENDPOINT}/v1beta/models/fast:generateContent`,
    {
      method: 'POST',
      headers,
      body: JSON.stringify({
        contents: [{ parts: [{ text: message }] }],
      }),
    }
  );

  if (!response.ok) {
    const error = await response.text();
    return c.json({ error }, response.status);
  }

  const data = await response.json() as any;
  const reply = data.candidates?.[0]?.content?.parts?.[0]?.text || '';

  return c.json({ reply });
});

export default app;
```

## Frontend Calling Your Backend

```typescript
// In development: pass session token
// In production: pass SDK auth token (if user is logged in)
const token = Nxcode.auth.isLoggedIn() ? Nxcode.auth.getToken() : '';
const response = await fetch('/api/chat', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
    'X-Session-Token': token || '',
  },
  body: JSON.stringify({ message: 'Hello' }),
});
```

## After Deployment: Set NXCODE_APP_ID

After `nxcode deploy`, the output JSON includes `app_id`. Set it as a secret:

```bash
# Get app_id from the deploy output JSON
nxcode secret set my-api NXCODE_APP_ID "deploy_abc123def456"
```

Or add it to `wrangler.toml` `[vars]` section (non-sensitive, can be in code):

```toml
[vars]
NXCODE_APP_ID = "deploy_abc123def456"
```
