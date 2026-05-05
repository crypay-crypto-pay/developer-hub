# Quick Start — Create a Payment in 5 Minutes

This guide walks you through creating a cryptocurrency payment using the Crypay API.

## Prerequisites

- A [Crypay account](https://app.crypay.com/register)
- An API key (see [Authentication](authentication.md))

## Step 1 — Create an API Key

1. Log in to [app.crypay.com](https://app.crypay.com)
2. Go to **Settings → API Keys → New Key**
3. Name your key and select the **PAYMENT** scope
4. Copy both the `apiKey` and `secretKey` — the secret is shown only once

## Step 2 — Create a Payment

```bash
curl -X POST https://app.crypay.com/api/payments \
  -H "X-API-KEY: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 19.99,
    "currency": "EUR",
    "reference": "ORDER-001",
    "successUrl": "https://yourshop.com/success",
    "failUrl": "https://yourshop.com/cancel",
    "paymentUpdateWebhook": "https://yourshop.com/webhook/crypay",
    "paymentUpdateWebhookSecret": "your-webhook-secret"
  }'
```

You'll receive a payment object:

```json
{
  "id": "507f1f77bcf86cd799439011",
  "shortId": "abc123de",
  "state": "NEW",
  "amount": 19.99,
  "currency": "EUR",
  "reference": "ORDER-001",
  "created": "2026-05-05T10:00:00.000Z"
}
```

## Step 3 — Redirect the Customer

Send your customer to the payment page using the `shortId`:

```
https://app.crypay.com/pay/{shortId}
```

The customer selects their preferred cryptocurrency. The payment state transitions to `WAITING_FOR_PAYMENT` and an address is assigned.

## Step 4 — Receive a Webhook

When payment is confirmed, Crypay sends a POST request to your `paymentUpdateWebhook` URL:

```json
{
  "paymentId": "507f1f77bcf86cd799439011",
  "reference": "ORDER-001",
  "status": "SUCCESS",
  "amount": 19.99,
  "currency": "EUR",
  "symbol": "BTC",
  "network": "bitcoin",
  "paymentAmount": 0.00050123
}
```

Verify the `X-SIGNATURE` header before fulfilling the order (see [Webhooks](webhooks.md)).

## Payment States

| State | Meaning |
|-------|---------|
| `NEW` | Created, customer has not selected a coin yet |
| `WAITING_FOR_PAYMENT` | Crypto address assigned, awaiting on-chain transaction |
| `WAITING_FOR_CONFIRMATION` | Transaction seen, waiting for block confirmations |
| `SUCCESS` | Confirmed — safe to fulfill the order |
| `EXPIRED` | Payment window closed before payment arrived |

## Next Steps

- [Full payment reference](payments.md) — all fields, list/filter, option selection
- [Webhook verification](webhooks.md) — HMAC, retry policy, best practices
- [Error codes](errors.md) — handling edge cases
