---
name: build-billing
description: Adds balance display and top-up features via Nxcode SDK. Use when user needs to show balance, let users top up, or manage user funds.
---

# Build Billing Features

Use this skill when the user needs:
- Display user's balance
- Let users top up / recharge
- Show billing information
- Manage user funds

**Requires**: `build-auth` skill (users must be logged in)

## Quick Start

```bash
npm install @nxcode/sdk
```

Or use CDN for plain HTML:

```html
<script src="https://cdn.jsdelivr.net/npm/@nxcode/sdk@latest/dist/nxcode.min.js"></script>
```

The SDK auto-configures when running on the Nxcode platform (development preview or deployed app). No manual configuration needed.

## Check Balance

```javascript
// Get current balance
const balance = await Nxcode.billing.getBalance();
console.log('Current balance:', balance, 'C$');
```

## Open Top-up Page

```javascript
// Opens Nxcode top-up page in new tab
Nxcode.billing.topUp();
```

## React Example: Balance Display

```tsx
import { useState, useEffect } from 'react';
import Nxcode from '@nxcode/sdk';

function WalletCard() {
  const [balance, setBalance] = useState<number | null>(null);
  const [user, setUser] = useState(null);

  useEffect(() => {
    const unsubscribe = Nxcode.auth.onAuthStateChange(async (user) => {
      setUser(user);
      if (user) {
        const bal = await Nxcode.billing.getBalance();
        setBalance(bal);
      }
    });
    return () => unsubscribe();
  }, []);

  if (!user) return <p>Please login</p>;

  return (
    <div className="wallet-card">
      <p>Balance: {balance?.toFixed(2)} C$</p>
      <button onClick={() => Nxcode.billing.topUp()}>Top Up</button>
    </div>
  );
}
```

## Low Balance Warning

```javascript
async function checkBalanceBeforeAction() {
  const balance = await Nxcode.billing.getBalance();

  if (balance < 10) {
    const shouldTopUp = confirm(
      `Your balance is low (${balance.toFixed(2)} C$). Would you like to top up?`
    );
    if (shouldTopUp) {
      Nxcode.billing.topUp();
      return false;  // Don't proceed
    }
  }

  return true;  // OK to proceed
}
```

## Balance in User Profile

```javascript
// Display balance alongside user info
Nxcode.auth.onAuthStateChange((user) => {
  if (user) {
    // User object includes balance
    document.getElementById('user-name').textContent = user.name;
    document.getElementById('user-balance').textContent = user.balance.toFixed(2) + ' C$';
  }
});
```

## API Reference

| Method | Description |
|--------|-------------|
| `Nxcode.billing.getBalance()` | Get user's current C$ balance |
| `Nxcode.billing.topUp()` | Open top-up page in new tab |

## Note on Balance

The balance returned is the user's **spendable balance** in C$ (platform credits). This balance is used for:
- AI usage (when app uses `build-ai-app` with user-pays mode)
- In-app purchases (when app uses `build-payment`)

## DO NOT

- **DO NOT** try to modify user balance directly
- **DO NOT** implement your own top-up flow - use `Nxcode.billing.topUp()`
