# Quickstart — Create a Payment in 5 Minutes

This guide walks you through creating a Crypay payment and receiving a webhook confirmation.

## Prerequisites

- A Crypay merchant account → [crypay.com](https://crypay.com)
- Your **API key** from the merchant dashboard

---

## Step 1 — Create a payment

```bash
curl -X POST https://api.crypay.com/payments \
  -H "X-API-KEY: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 49.99,
    "currency": "EUR",
    "reference": "ORDER-001",
    "paymentUpdateWebhook": "https://yoursite.com/webhooks/crypay"
  }'
```

**Response (201 Created):**

```json
{
  "id": "abc123xyz456",
  "link": "https://pay.crypay.com/abc123xyz456"
}
```

---

## Step 2 — Redirect your customer

Send the customer to `link`. They'll see available cryptocurrencies, select one, and receive a payment address.

---

## Step 3 — Handle the webhook

When the payment status changes, Crypay POSTs to your `paymentUpdateWebhook` URL:

```json
{
  "paymentId": "abc123xyz456",
  "reference": "ORDER-001",
  "status": "SUCCESS",
  "amount": 49.99,
  "currency": "EUR",
  "symbol": "BTC",
  "network": "BITCOIN",
  "paymentAmount": 0.00078
}
```

Possible `status` values: `WAITING_FOR_PAYMENT` → `WAITING_FOR_CONFIRMATION` → `SUCCESS` (or `EXPIRED`).

Verify the request is authentic before fulfilling the order:

```javascript
const crypto = require('crypto');

function verifyWebhook(rawBody, signature, secret) {
  const expected = crypto
    .createHmac('sha256', Buffer.from(secret, 'utf-8'))
    .update(Buffer.from(rawBody, 'utf-8'))
    .digest('hex');
  return expected.toLowerCase() === signature.toLowerCase();
}
```

---

## Step 4 — Verify on the Crypay side (optional)

```bash
curl https://api.crypay.com/payments/abc123xyz456 \
  -H "X-API-KEY: YOUR_API_KEY"
```

Check the `state` field: `NEW` → `WAITING_FOR_PAYMENT` → `WAITING_FOR_CONFIRMATION` → `SUCCESS`.

---

## Next Steps

- [Authentication](authentication.md) — API key details and HMAC signing
- [Payments reference](payments.md) — full request/response schema
- [Webhooks](webhooks.md) — retry policy, security headers
- [Examples](../../examples/curl/) — ready-to-run curl scripts
