---
name: expo-web-guide
description: Provides configuration guidelines for Expo apps with Web support. Use when working on expo-hono or expo-fastapi templates.
---

# Expo Web Development Guide

This guide covers critical configuration requirements for Expo projects with Web support.

## Critical Configuration - DO NOT CHANGE

### 1. Bundler Must Be Metro

The `app.json` must use **metro** bundler, NOT webpack:

```json
{
  "expo": {
    "web": {
      "bundler": "metro",  // DO NOT change to "webpack"
      "output": "static"
    }
  }
}
```

**Why?** Webpack has compatibility issues with:
- `nanoid` ESM exports → `(0, r.nanoid) is not a function`
- `expo-router` static routes → `Unmatched Route`

### 2. API URLs Must Be Full URLs

In `src/lib/api.ts`, always use full URLs, NOT relative paths:

```typescript
// CORRECT - Full URL
const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:8000'

// WRONG - Relative path (won't work in Expo Web)
const API_URL = Platform.OS === 'web' ? '' : 'http://localhost:8000'
```

**Why?** Expo Web static builds don't have a proxy server. Relative paths like `/api/...` will return HTML instead of JSON.

### 3. Babel Config for Reanimated

If using `react-native-reanimated`, the babel config must include the plugin:

```javascript
// babel.config.js
module.exports = {
  presets: ['babel-preset-expo'],
  plugins: ['react-native-reanimated/plugin'],  // MUST be last
};
```

## Common Errors and Fixes

### Error: `(0, r.nanoid) is not a function`

**Cause:** Webpack bundler with nanoid ESM compatibility issue.

**Fix:** Change bundler to metro in `app.json`:
```json
"web": {
  "bundler": "metro"
}
```

### Error: `Unmatched Route`

**Cause:** Webpack static export doesn't properly handle expo-router routes.

**Fix:** Use metro bundler (see above).

### Error: `__reanimatedLoggerConfig is not defined`

**Cause:** `react-native-reanimated` version incompatible with Web.

**Fix:**
1. Add reanimated babel plugin (see above)
2. If still failing, downgrade reanimated:
```bash
npm install react-native-reanimated@3.10.1 --legacy-peer-deps
```

### Error: API returns HTML instead of JSON

**Cause:** Using relative API paths in Expo Web.

**Fix:** Use full URL in `api.ts`:
```typescript
const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:8000'
```

## Building for Web

### Development (with hot reload)
```bash
cd app
npx expo start --web
```

### Production Build
```bash
cd app
npx expo export -p web --output-dir web-build
```

### Serving the Build
```bash
# Use the serve_spa.py script or any static server
python3 serve_spa.py --root ./web-build --port 5173
nxcode report-preview --port 5173 --framework expo
```

## Dependency Compatibility Table

| Expo SDK | react-native-reanimated | expo-router | Notes |
|----------|------------------------|-------------|-------|
| 52.x | 3.10.x | 4.x | Use reanimated 3.10 for Web |
| 51.x | 3.8.x | 3.x | |

## DO NOT

- **DO NOT** change `bundler` from `metro` to `webpack` in `app.json`
- **DO NOT** use relative API paths (empty string or `/api/...`) for Web
- **DO NOT** remove `react-native-reanimated/plugin` from babel config
- **DO NOT** upgrade `react-native-reanimated` beyond tested versions without verifying Web compatibility
