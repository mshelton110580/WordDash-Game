---
name: build-payment
description: Adds in-app purchases and payment processing via Nxcode SDK. Use when user needs to charge users, sell features, or accept payments.
---

# Build In-App Payments

Use this skill when the user needs:
- Sell premium features
- In-app purchases
- Subscription-like payments
- Accept tips/donations

**Requires**: `build-auth` skill (users must be logged in to pay)

## Quick Start

```bash
npm install @nxcode/sdk
```

Or use CDN for plain HTML:

```html
<script src="https://cdn.jsdelivr.net/npm/@nxcode/sdk@latest/dist/nxcode.min.js"></script>
```

The SDK auto-configures when running on the Nxcode platform (development preview or deployed app). No manual configuration needed.

## Basic Payment

```javascript
// Charge user for a feature
const result = await Nxcode.payment.charge({
  amount: 50,  // 50 C$
  description: "Unlock Premium Features"
});

if (result.success) {
  console.log('Payment successful!');
  console.log('Transaction ID:', result.transactionId);
  enablePremiumFeatures();
} else {
  console.error('Payment failed:', result.error);
}
```

## Handle Insufficient Balance

```javascript
async function purchaseFeature() {
  const result = await Nxcode.payment.charge({
    amount: 100,
    description: "Pro Plan - 1 Month"
  });

  if (result.success) {
    grantProAccess();
  } else if (result.error?.includes('Insufficient balance')) {
    // Prompt user to top up
    if (confirm('Insufficient balance. Would you like to top up?')) {
      Nxcode.billing.topUp();  // Opens top-up page
    }
  }
}
```

## Payment with Metadata

Store custom data with the transaction:

```javascript
const result = await Nxcode.payment.charge({
  amount: 25,
  description: "Game Coins - 1000 pack",
  metadata: {
    item_type: "coins",
    quantity: 1000,
    user_level: 5
  }
});

if (result.success) {
  // Use metadata to fulfill the purchase
  addCoinsToUser(1000);
}
```

## Get Transaction History

```javascript
const transactions = await Nxcode.payment.getTransactions();

transactions.forEach(tx => {
  console.log(`${tx.description}: ${tx.amount} C$ - ${tx.createdAt}`);
});
```

## React Example: Premium Unlock

```tsx
import { useState } from 'react';
import Nxcode from '@nxcode/sdk';

function PremiumCard() {
  const [status, setStatus] = useState<'idle' | 'processing' | 'purchased'>('idle');

  const handlePurchase = async () => {
    if (!Nxcode.auth.isLoggedIn()) {
      await Nxcode.auth.login();
    }

    setStatus('processing');

    try {
      const result = await Nxcode.payment.charge({
        amount: 50,
        description: "Premium Plan",
        metadata: { plan: "premium", duration: "lifetime" }
      });

      if (result.success) {
        setStatus('purchased');
      } else if (result.error?.includes('Insufficient')) {
        if (confirm('Not enough balance. Top up now?')) {
          Nxcode.billing.topUp();
        }
        setStatus('idle');
      } else {
        alert('Payment failed: ' + result.error);
        setStatus('idle');
      }
    } catch (error) {
      alert('Error: ' + error.message);
      setStatus('idle');
    }
  };

  return (
    <div className="premium-card">
      <h2>Premium Plan</h2>
      <p>50 C$</p>
      <button onClick={handlePurchase} disabled={status !== 'idle'}>
        {status === 'processing' ? 'Processing...' :
         status === 'purchased' ? 'Premium Active' : 'Unlock Premium'}
      </button>
    </div>
  );
}
```

## Revenue Split

When users pay through your app:

| Recipient | Share |
|-----------|-------|
| **You (Creator)** | 70% |
| **Platform** | 30% |

Example: User pays 100 C$ → You receive 70 C$

```javascript
const result = await Nxcode.payment.charge({ amount: 100, description: "Pro" });
console.log('Your earnings:', result.creatorShare);  // 70
```

## Types

```typescript
interface ChargeOptions {
  amount: number;       // Amount in C$
  description: string;  // Shown to user
  metadata?: object;    // Optional custom data (order ID, item info, etc.)
}

interface ChargeResult {
  success: boolean;
  transactionId?: string;
  amount?: number;
  creatorShare?: number;  // Your 70% share
  newBalance?: number;    // User's remaining balance
  error?: string;
}

interface Transaction {
  id: string;
  amount: number;
  description: string;
  metadata: object;
  createdAt: string;
}
```

## API Reference

| Method | Description |
|--------|-------------|
| `Nxcode.payment.charge(options)` | Process payment. Returns ChargeResult |
| `Nxcode.payment.getTransactions(limit?, offset?)` | Get transaction history |

## Common Use Cases

### One-time Purchase
```javascript
await Nxcode.payment.charge({
  amount: 50,
  description: "Remove Ads Forever"
});
```

### Virtual Currency
```javascript
await Nxcode.payment.charge({
  amount: 10,
  description: "500 Gold Coins",
  metadata: { coins: 500 }
});
```

### Tips/Donations
```javascript
await Nxcode.payment.charge({
  amount: userSelectedAmount,
  description: `Tip: ${userSelectedAmount} C$`,
  metadata: { type: "tip" }
});
```

## DO NOT

- **DO NOT** implement your own payment system
- **DO NOT** store payment credentials
- **DO NOT** process payments without user confirmation (charge shows a confirmation UI)
