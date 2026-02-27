# Framework Default Ports Reference

## JavaScript/TypeScript Frameworks

| Framework | Default Port | Host Flag | Notes |
|-----------|-------------|-----------|-------|
| Vite | 5173 | `--host 0.0.0.0` | React, Vue, Svelte, Vanilla |
| Next.js | 3000 | N/A (binds all by default) | |
| Nuxt 3 | 3000 | `--host 0.0.0.0` | |
| Astro | 4321 | `--host 0.0.0.0` | |
| SvelteKit | 5173 | `--host 0.0.0.0` | Uses Vite |
| Create React App | 3000 | `HOST=0.0.0.0` env var | |
| Remix | 3000 | Depends on adapter | |
| Angular | 4200 | `--host 0.0.0.0` | |
| Gatsby | 8000 | `--host 0.0.0.0` | |
| Docusaurus | 3000 | `--host 0.0.0.0` | |

## API Frameworks (JavaScript)

| Framework | Default Port | Command |
|-----------|-------------|---------|
| Hono (dev) | 3000 | `npm run dev` |
| Hono (wrangler) | 8787 | `wrangler dev` |
| Express | 3000 | Custom |
| Fastify | 3000 | Custom |

## Python Frameworks

| Framework | Default Port | Command |
|-----------|-------------|---------|
| FastAPI | 8000 | `uvicorn main:app --reload --host 0.0.0.0` |
| Flask | 5000 | `flask run --host 0.0.0.0` |
| Django | 8000 | `python manage.py runserver 0.0.0.0:8000` |
| Streamlit | 8501 | `streamlit run app.py` |

## Static Servers

| Tool | Default Port | Command |
|------|-------------|---------|
| http-server | 8080 | `http-server -p 3000` |
| serve | 3000 | `serve -l 3000` |
| Python http | 8000 | `python -m http.server 3000` |

## Port Conflicts Resolution

Common port conflicts and solutions:

| Port | Commonly used by | Alternative |
|------|-----------------|-------------|
| 3000 | Next.js, CRA, many others | 3001, 3002 |
| 5173 | Vite | 5174, 5175 |
| 8000 | Django, FastAPI | 8001, 8080 |
| 8080 | http-server, Tomcat | 8081 |

## Environment Variables for Port Override

| Framework | Env Var | Example |
|-----------|---------|---------|
| Vite | `--port` flag | `npm run dev -- --port 3001` |
| Next.js | `PORT` | `PORT=3001 npm run dev` |
| CRA | `PORT` | `PORT=3001 npm start` |
| FastAPI/Uvicorn | `--port` flag | `uvicorn main:app --port 8001` |
| Flask | `--port` flag | `flask run --port 5001` |
