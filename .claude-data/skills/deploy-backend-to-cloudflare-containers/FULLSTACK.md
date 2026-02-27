# Full-Stack Deployment: Frontend + Container Backend

Serve static frontend via Cloudflare's asset hosting, route `/api/*` to containerized backend.

## Project Structure

```
my-app/
├── dist/                 # Built frontend (React/Vue/etc)
│   └── index.html
├── backend/
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── src/
│   └── index.js          # Worker router
├── package.json          # MUST have @cloudflare/containers
└── wrangler.toml
```

## wrangler.toml

```toml
name = "my-app"
main = "src/index.js"

[observability]
enabled = true

[assets]
directory = "./dist"
binding = "ASSETS"

[[containers]]
class_name = "Backend"
image = "./backend/Dockerfile"
max_instances = 3

[[durable_objects.bindings]]
class_name = "Backend"
name = "BACKEND"

[[migrations]]
new_sqlite_classes = ["Backend"]
tag = "v1"
```

## Worker Router (src/index.js)

```javascript
import { Container, getRandom } from "@cloudflare/containers";

class Backend extends Container {
  defaultPort = 8000;
  sleepAfter = "2h";
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname.startsWith("/api")) {
      const container = await getRandom(env.BACKEND, 3);
      await container.start();
      return container.fetch(request);
    }

    return env.ASSETS.fetch(request);
  },
};

export { Backend };
```

## Frontend API Calls

```javascript
// CORRECT - relative path, routed by Worker
fetch('/api/widgets')

// WRONG - will not work, different origin
fetch('http://localhost:8000/api/widgets')
```

## Deploy

```bash
# Build frontend first
cd frontend && npm run build && cp -r dist ../dist

# Deploy everything
cd .. && nxcode deploy --type container --dir .
```
