---
name: build-ai-app
description: Adds AI features (chatbot, assistant, content generation) via the platform AI Gateway. Use when user wants to create chatbot, AI assistant, or any app that calls LLM APIs.
---

# Build AI Applications

When user wants to build AI-powered features (chatbot, assistant, content generation, etc.), use the platform's AI Gateway.

## Need User Login?

If the user mentions any of these, also use the `build-auth` skill:
- Users need to login
- Track per-user conversations / data
- User pays for AI usage (instead of creator)
- Personalized experience per user

## Available Models

Only use these models:

| Alias | Full Name | Best For |
|-------|-----------|----------|
| `fast` | `gemini-3-flash-preview` | General tasks, high volume |
| `pro` | `gemini-3-pro-preview` | Complex reasoning, coding |

**Use the alias (`fast` or `pro`) in your code** - the gateway resolves them automatically.

## AI Gateway Endpoint

All AI calls go through the unified gateway:

```
https://studio-api.nxcode.io/api/ai-gateway
```

## Two Environments — Different Auth

| | Development (Preview) | Production (Deployed) |
|---|---|---|
| **Frontend** | SDK auto-configures via Origin | SDK auto-configures via Origin |
| **Backend auth header** | `X-Workspace-Id` + `X-Session-Token` | `X-App-Id` (+ optional `Authorization`) |
| **Where IDs come from** | `THREAD_ID` env var (container) | `NXCODE_APP_ID` wrangler.toml var |
| **Who pays** | Thread owner (developer) | Creator pays (default) or User pays |

**Frontend SDK works identically in both environments — zero code changes needed.**

**Backend code needs a small change when deploying** — see [BACKEND_HONO.md](BACKEND_HONO.md) and [BACKEND_PYTHON.md](BACKEND_PYTHON.md).

---

## Frontend: Using the SDK (Recommended)

The Nxcode SDK provides a simple API for AI calls from the browser.

### Setup

```bash
npm install @nxcode/sdk
```

Or use CDN for plain HTML:

```html
<script src="https://cdn.jsdelivr.net/npm/@nxcode/sdk@latest/dist/nxcode.min.js"></script>
```

The SDK auto-configures in both environments:
- **Dev preview** (`thr-xxx.localhost:8080`): SDK detects preview Origin → gets `appId: "dev_{short_id}"`
- **Deployed** (`thr-xxx-my-app.nxcode-io.workers.dev`): SDK detects deployed Origin → gets `appId: "deploy_{id}"`

No manual configuration needed.

### Simple Text Generation

```javascript
const response = await Nxcode.ai.generate({
  prompt: 'Write a haiku about coding',
  model: 'fast'  // or 'pro'
});
console.log(response.text);
```

### Chat with History

```javascript
const response = await Nxcode.ai.chat({
  messages: [
    { role: 'user', content: 'Hello!' },
    { role: 'assistant', content: 'Hi! How can I help?' },
    { role: 'user', content: 'What is TypeScript?' }
  ],
  model: 'fast'
});
console.log(response.content);
```

### Streaming Responses

```javascript
await Nxcode.ai.generateStream({
  prompt: 'Write a short story',
  model: 'fast',
  onChunk: (chunk) => {
    document.body.innerText += chunk.content;
    if (chunk.done) console.log('Done!');
  }
});

await Nxcode.ai.chatStream({
  messages: [{ role: 'user', content: 'Tell me a joke' }],
  onChunk: (chunk) => {
    outputDiv.innerText += chunk.content;
  }
});
```

### With Images (Multimodal)

```javascript
const response = await Nxcode.ai.chat({
  messages: [{
    role: 'user',
    content: [
      { type: 'text', text: 'What is in this image?' },
      { type: 'image', data: base64ImageData, mimeType: 'image/png' }
    ]
  }],
  model: 'fast'
});
```

### SDK Methods Reference

| Method | Purpose | Returns |
|--------|---------|---------|
| `Nxcode.ai.generate(options)` | Single prompt → text | `{ text, usage }` |
| `Nxcode.ai.chat(options)` | Multi-turn conversation | `{ content, usage }` |
| `Nxcode.ai.generateStream(options)` | Stream single prompt | callback |
| `Nxcode.ai.chatStream(options)` | Stream conversation | callback |
| `Nxcode.ai.createAgent(options)` | Create agent with tools | `Agent` instance |

### Structured Output (responseSchema)

```javascript
const response = await Nxcode.ai.generate({
  prompt: 'Extract info: John is 25 years old and likes coding.',
  responseSchema: {
    name: 'string',
    age: 'number',
    hobbies: ['string']
  }
});
const data = JSON.parse(response.text);
```

**Schema Syntax:**
- Primitives: `'string'`, `'number'`, `'boolean'`
- Arrays: `['string']`, `['number']`, `[{ nested: 'object' }]`
- Objects: `{ key: 'type', nested: { ... } }`

### AI Agents (Tool Calling)

Create AI agents that can call your backend endpoints as tools. See [AGENTS.md](AGENTS.md) for full reference with tool endpoint format.

```javascript
const agent = Nxcode.ai.createAgent({
  instructions: 'You are a helpful email assistant.',
  tools: [
    {
      name: 'search_emails',
      description: 'Search emails by query',
      parameters: { query: 'string', limit: 'number' },
      endpoint: '/api/emails/search'
    }
  ],
  model: 'fast',
  maxSteps: 10
});

const result = await agent.run('Find emails from John');
console.log(result.output);
```

### SDK Utility Methods

```javascript
await Nxcode.ready();
const config = Nxcode.getConfig();
if (Nxcode.isReady()) { /* SDK configured */ }
```

---

## Backend AI Calls

For most AI apps, call AI directly from the frontend using the SDK — it's simpler and handles auth automatically. Only use backend AI calls when you need server-side processing (saving to DB, combining with other data, etc).

- **Hono/TypeScript (Cloudflare Workers)**: See [BACKEND_HONO.md](BACKEND_HONO.md)
- **Python/FastAPI (Cloudflare Containers)**: See [BACKEND_PYTHON.md](BACKEND_PYTHON.md)

---

## Billing Modes

Deployed apps default to **Creator Pays** mode. You can change the billing mode after deployment in the Nxcode dashboard:

**Menu → My Workspaces → Apps → select your app → Settings**

| Mode | Who Pays | Users Login? | Use Case |
|------|----------|-------------|----------|
| **Creator Pays** (default) | You (the developer) | No | Free tools, demos, low-traffic apps |
| **User Pays** | End users | Yes (required) | Commercial apps, high usage |

### Creator Pays (Default)

- Users can use the app anonymously — no login required
- AI costs are charged to your (the creator's) account
- Rate limits apply to prevent abuse (configurable in dashboard)
- Good for demos, free tools, and low-traffic apps

### User Pays

- Users **must** login before using AI features — use `Nxcode.auth.login()` (see `build-auth` skill)
- AI costs are deducted from the user's C$ balance
- No rate limits (user pays per use)
- If a user's balance is insufficient, prompt them to top up via `Nxcode.billing.topUp()` (see `build-billing` skill)
- Required for commercial apps or high-usage scenarios

### Switching Modes

1. Deploy your app with `nxcode deploy`
2. Go to **Menu → My Workspaces → Apps**
3. Select your app → **Settings**
4. Change billing mode to "User Pays" if needed
5. If switching to User Pays, make sure your frontend code includes login flow (use `build-auth` skill)

**Tell the user**: After deployment, remind the user to check their app's billing settings in the dashboard if they want to change the default Creator Pays mode.

---

## DO NOT

- **DO NOT** use `generativelanguage.googleapis.com` directly
- **DO NOT** use models not listed above (`fast` or `pro` only)
- **DO NOT** hardcode API keys - the platform handles authentication
- **DO NOT** use OpenAI or Anthropic APIs - only Gemini is available through this gateway
- **DO NOT** deploy FastAPI to Cloudflare Python Workers - use Containers instead
- **DO NOT** use `X-Workspace-Id` in production code - it only works in dev containers
