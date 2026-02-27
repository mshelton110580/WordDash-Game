---
name: nxcode-cli-basics
description: Initializes new Nxcode projects using the nxcode init command. Use when user wants to create a new project, start from a template, or asks about available templates.
---

# Initialize Nxcode Projects

When user wants to create a new project, use the `nxcode init` command.

## Command Format

```bash
nxcode init <template> [project-name] [options]
```

- `<template>` - Required: template name (e.g., vite-react-hono, next, expo)
- `[project-name]` - Optional: project directory name (defaults to template name)
- `[options]` - Optional: module flags (--auth, --ai, --payment, etc.)

## List Available Templates

```bash
nxcode init --list
```

This shows all available templates in real-time.

## Module Options

| Flag | Description |
|------|-------------|
| `--auth` | Add Nxcode Auth module (OAuth login) |
| `--ai` | Add AI module (chat, generate) |
| `--payment` | Add Payment module (in-app purchases) |
| `--admin` | Add Admin module (dashboard, user management) |
| `--i18n` | Add i18n module (multi-language, RTL support) |
| `--realtime` | Add Realtime module (WebSocket, SSE) |
| `--seo` | Add SEO module (sitemap, meta tags, structured data) |
| `--blog` | Add Blog module (posts, categories, tags, RSS feed) |
| `--full` | Add core modules (auth + ai + payment) |

## Examples

```bash
# Basic frontend project
nxcode init vite-react my-app

# Full-stack with authentication
nxcode init vite-react-hono my-app --auth

# Next.js with SEO and i18n
nxcode init next-hono my-app --seo --i18n

# All core features
nxcode init vite-react-hono my-app --full

# All features including admin
nxcode init vite-react-hono my-app --full --admin

# Mobile app with AI
nxcode init expo-hono my-app --ai --realtime

# Blog site with SEO
nxcode init next-hono my-blog --blog --seo
```

## Typical Workflow

```bash
# 1. List available templates
nxcode init --list

# 2. Initialize project with desired modules
nxcode init vite-react-hono my-app --auth --ai

# 3. IMPORTANT: Install dependencies separately (nxcode init does NOT install them)
cd my-app
npm install
cd frontend && npm install && cd ..
cd backend && npm install && cd ..

# 4. Start development (see skill: start-dev-server)
cd my-app/backend
nohup npm run dev > /tmp/backend-dev.log 2>&1 &
sleep 3
nxcode report-preview --port 3001

# Start frontend
cd my-app/frontend
nohup npm run dev > /tmp/frontend-dev.log 2>&1 &
sleep 3
nxcode report-preview --port 5173
```

## CRITICAL: Installing Dependencies

**`nxcode init` only creates project files - it does NOT install dependencies.**

You MUST run `npm install` in each directory that has a `package.json`:

```bash
# After nxcode init, run these commands separately:
cd my-app
npm install                              # Root dependencies (if package.json exists)
cd frontend && npm install && cd ..      # Frontend dependencies
cd backend && npm install && cd ..       # Backend dependencies
```

**Why separate commands?**
- Each `npm install` takes 5-10 seconds
- Running all installs in one command may timeout
- If one install fails, you can retry just that directory

## After Initialization

**Start development server:**
See skill: `start-dev-server`

**Deploy the project:**
- Frontend: See skill `deploy-frontend-to-cloudflare`
- Backend: See skill `deploy-backend-to-cloudflare` or `deploy-backend-to-cloudflare-containers`

## Notes

- The command is **non-interactive** - all options must be specified via flags
- Use `nxcode init --list` to see current available templates
- Use `nxcode init --help` to see all options and examples
