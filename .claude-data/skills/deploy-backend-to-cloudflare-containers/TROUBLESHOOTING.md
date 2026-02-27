# Troubleshooting Container Deployments

## "Could not resolve @cloudflare/containers"

Missing package.json or dependency. Create package.json with:

```json
{
  "type": "module",
  "dependencies": {
    "@cloudflare/containers": "^0.1.0"
  }
}
```

## "Container crashed while checking for ports"

**Most common cause**: Using native Node.js modules that fail to build for linux/amd64.

**Solution**:
- Do NOT use: `sqlite3`, `better-sqlite3`, `bcrypt`, `sharp`, `canvas`
- Use D1 for database (see [D1_ACCESS.md](D1_ACCESS.md))
- Use pure JS alternatives: `bcryptjs` instead of `bcrypt`

## "The container is not running, consider calling start()"

Worker code is missing `container.start()`. Update your Worker:

```javascript
// Wrong
const container = await getRandom(env.BACKEND, 1);
return container.fetch(request);

// Correct
const container = await getRandom(env.BACKEND, 1);
await container.start();  // Wake container if sleeping
return container.fetch(request);
```

## Container Not Starting

1. Check Dockerfile syntax: ensure `FROM --platform=linux/amd64` is present
2. Check for native modules in package.json
3. View container logs: `nxcode logs <worker-name>`

## 502 Bad Gateway

- Container crashed or port mismatch
- Check `defaultPort` in Worker matches `EXPOSE` in Dockerfile
- View container logs: `nxcode logs <worker-name>`

## Slow Cold Start

- Containers take 2-10s to cold start
- Use `sleepAfter` to keep warm (e.g., `sleepAfter = "2h"`)
- Consider `max_instances` for pre-warming

## Database Errors / Data Lost After Redeploy

**Cause**: Using local SQLite or file-based storage.

**Solution**: Use D1 via Worker proxy. See [D1_ACCESS.md](D1_ACCESS.md). D1 data persists across deploys.

## Startup Log Debugging

1. Ensure wrangler.toml has `[observability] enabled = true`
2. Use `wrangler tail your-worker-name` to see container logs
3. Common issues:
   - Python import errors (check PYTHONPATH in Dockerfile)
   - Missing dependencies (check requirements.txt)
   - PostgreSQL schema syntax (D1 is SQLite-based! See [D1_SCHEMA.md](D1_SCHEMA.md))
