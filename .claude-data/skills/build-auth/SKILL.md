---
name: build-auth
description: Adds user authentication (login, logout, user accounts) via Nxcode SDK. Use when user needs login, user accounts, or identity features.
---

# Build User Authentication

Use this skill when the user needs:
- User login/logout
- User accounts
- User-specific data or features
- Identity management

## Quick Start

```bash
npm install @nxcode/sdk
```

Or use CDN for plain HTML:

```html
<script src="https://cdn.jsdelivr.net/npm/@nxcode/sdk@latest/dist/nxcode.min.js"></script>
```

The SDK auto-configures when running on the Nxcode platform (development preview or deployed app). No manual configuration needed.

## Basic Authentication

```javascript
// Login with Google/GitHub popup
const user = await Nxcode.auth.login();
console.log('Logged in:', user.email);
console.log('User ID:', user.id);

// Check if logged in
if (Nxcode.auth.isLoggedIn()) {
  const user = Nxcode.auth.getUser();
  console.log('Current user:', user.name);
}

// Logout
await Nxcode.auth.logout();
```

## Listen for Auth State Changes

```javascript
// Called when user logs in or out
Nxcode.auth.onAuthStateChange((user) => {
  if (user) {
    console.log('User logged in:', user.email);
    showUserDashboard(user);
  } else {
    console.log('User logged out');
    showLoginPage();
  }
});
```

## Get Auth Token for API Calls

When your backend needs to verify the user:

```javascript
// Frontend: Get token and send to backend
const token = Nxcode.auth.getToken();

const response = await fetch('/api/my-endpoint', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```

```python
# Backend: Verify token
from fastapi import FastAPI, Request, HTTPException

@app.get("/api/my-endpoint")
async def my_endpoint(request: Request):
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(401, "Not authenticated")

    token = auth_header.replace("Bearer ", "")
    # Token is verified by Nxcode - just use it for AI gateway calls
    # or call /api/sdk/auth/me to get user info
```

## React Example

```tsx
import { useState, useEffect } from 'react';
import Nxcode from '@nxcode/sdk';

function App() {
  const [user, setUser] = useState(null);

  useEffect(() => {
    const unsubscribe = Nxcode.auth.onAuthStateChange((user) => {
      setUser(user);
    });
    return () => unsubscribe();
  }, []);

  const handleLogin = async () => {
    try {
      await Nxcode.auth.login();
    } catch (error) {
      console.error('Login failed:', error);
    }
  };

  if (!user) {
    return <button onClick={handleLogin}>Login</button>;
  }

  return (
    <div>
      <p>Welcome, {user.name}!</p>
      <button onClick={() => Nxcode.auth.logout()}>Logout</button>
    </div>
  );
}
```

## User Object

```typescript
interface User {
  id: string;          // Unique user ID
  email: string;       // User's email
  name: string | null; // Display name
  avatar: string | null; // Profile picture URL
  balance: number;     // C$ balance (for payment features)
}
```

## API Reference

| Method | Description |
|--------|-------------|
| `Nxcode.auth.login(provider?)` | Login via Google/GitHub popup. Returns user object |
| `Nxcode.auth.logout()` | Logout and clear session |
| `Nxcode.auth.getUser()` | Get current user or null |
| `Nxcode.auth.getToken()` | Get auth token for API calls |
| `Nxcode.auth.isLoggedIn()` | Check if user is logged in |
| `Nxcode.auth.onAuthStateChange(callback)` | Listen for auth changes. Returns unsubscribe function |

## DO NOT

- **DO NOT** implement your own auth system - use Nxcode SDK
- **DO NOT** store user credentials - SDK handles everything
- **DO NOT** call auth APIs directly - use SDK methods
