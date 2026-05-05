# Webhooks

Crypay sends HTTP POST callbacks to your server when a payment status changes.

---

## Setting Up a Webhook

Pass `paymentUpdateWebhook` (and optionally `paymentUpdateWebhookSecret`) when creating a payment:

```json
{
  "amount": 49.99,
  "currency": "EUR",
  "reference": "ORDER-001",
  "paymentUpdateWebhook": "https://yoursite.com/webhooks/crypay",
  "paymentUpdateWebhookSecret": "a-random-32-char-secret-you-generate"
}
```

Crypay will POST to that URL every time the payment state changes.

---

## Webhook Payload

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

### Status Values

| Status | Meaning |
|---|---|
| `WAITING_FOR_PAYMENT` | Crypto selected, address assigned |
| `WAITING_FOR_CONFIRMATION` | On-chain transaction seen, not yet confirmed |
| `SUCCESS` | Payment confirmed — safe to fulfil the order |
| `EXPIRED` | Payment timed out |

**Fulfil the order only on `SUCCESS`.** Earlier statuses are informational.

---

## Verifying the Signature

When `paymentUpdateWebhookSecret` is set, Crypay adds an `X-SIGNATURE` header:

```
X-SIGNATURE: 3a7b9c2d1e4f...  (HMAC-SHA256 hex digest of the raw body)
```

**Algorithm:** `HMAC-SHA256(key=secret, message=rawBody)` → hex

**Critical:** compute HMAC over the **raw request body bytes**, not over a parsed/re-serialised JSON object. Any whitespace difference will cause a mismatch.

### Node.js (Express)

```javascript
const express = require('express');
const crypto = require('crypto');

const app = express();
const WEBHOOK_SECRET = process.env.CRYPAY_WEBHOOK_SECRET;

// Use raw body middleware so we keep the original bytes
app.use('/webhooks/crypay', express.raw({ type: 'application/json' }));

app.post('/webhooks/crypay', (req, res) => {
  const signature = req.headers['x-signature'] ?? '';
  const rawBody = req.body; // Buffer

  if (!verifySignature(rawBody, signature, WEBHOOK_SECRET)) {
    return res.status(401).send('Invalid signature');
  }

  const event = JSON.parse(rawBody.toString('utf-8'));

  if (event.status === 'SUCCESS') {
    // Fulfil order event.reference
  }

  res.sendStatus(200);
});

function verifySignature(rawBody, signature, secret) {
  const expected = crypto
    .createHmac('sha256', Buffer.from(secret, 'utf-8'))
    .update(rawBody)
    .digest('hex');
  return expected.toLowerCase() === signature.toLowerCase();
}
```

### Python (Flask)

```python
import hmac, hashlib, os
from flask import Flask, request, abort

app = Flask(__name__)
WEBHOOK_SECRET = os.environ['CRYPAY_WEBHOOK_SECRET']

@app.route('/webhooks/crypay', methods=['POST'])
def crypay_webhook():
    raw_body = request.get_data()
    signature = request.headers.get('X-Signature', '')

    if not verify_signature(raw_body, signature, WEBHOOK_SECRET):
        abort(401)

    event = request.get_json(force=True)

    if event['status'] == 'SUCCESS':
        # Fulfil event['reference']
        pass

    return '', 200

def verify_signature(raw_body: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(
        secret.encode('utf-8'), raw_body, hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature.lower())
```

### PHP

```php
<?php
$webhookSecret = getenv('CRYPAY_WEBHOOK_SECRET');
$rawBody = file_get_contents('php://input');
$signature = $_SERVER['HTTP_X_SIGNATURE'] ?? '';

if (!verifySignature($rawBody, $signature, $webhookSecret)) {
    http_response_code(401);
    exit('Invalid signature');
}

$event = json_decode($rawBody, true);

if ($event['status'] === 'SUCCESS') {
    // Fulfil $event['reference']
}

http_response_code(200);

function verifySignature(string $rawBody, string $signature, string $secret): bool {
    $expected = hash_hmac('sha256', $rawBody, $secret);
    return hash_equals($expected, strtolower($signature));
}
```

---

## Delivery Policy

| Property | Value |
|---|---|
| Timeout | 10 seconds |
| Retries | None (failures are logged but not retried automatically) |
| Method | POST |
| Content-Type | `application/json` |

**Recommendation:** return a `2xx` response quickly and process the event asynchronously (queue it). If delivery fails, use `GET /payments/{id}` to poll for the current state.

---

## Testing Webhooks Locally

Use [ngrok](https://ngrok.com) or similar to expose a local server:

```bash
ngrok http 3000
# → https://abc123.ngrok.io

# Create a test payment pointing to your tunnel:
curl -X POST https://api.crypay.com/payments \
  -H "X-API-KEY: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1,
    "currency": "EUR",
    "reference": "TEST-001",
    "test": true,
    "paymentUpdateWebhook": "https://abc123.ngrok.io/webhooks/crypay",
    "paymentUpdateWebhookSecret": "test-secret-change-in-prod"
  }'
```
