# Webhooks

Crypay sends an HTTP POST request to your `paymentUpdateWebhook` URL whenever a payment state changes.

---

## Registering a Webhook

Set `paymentUpdateWebhook` and `paymentUpdateWebhookSecret` when creating a payment:

```json
{
  "amount": 19.99,
  "currency": "EUR",
  "paymentUpdateWebhook": "https://yourshop.com/webhooks/crypay",
  "paymentUpdateWebhookSecret": "whs_your_secret_here"
}
```

The webhook secret is used to sign the outbound payload. Choose a strong random value and store it securely.

---

## Webhook Payload

```http
POST /webhooks/crypay HTTP/1.1
Host: yourshop.com
Content-Type: application/json
X-SIGNATURE: 3d4e5f6a...  (hex, present only when secret was set)

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

### Payload Fields

| Field | Type | Description |
|-------|------|-------------|
| `paymentId` | string | Crypay internal payment ID |
| `reference` | string | Your order reference (passed at creation) |
| `status` | string | New payment state (see [states](payments.md#payment-states)) |
| `amount` | number | Fiat amount |
| `currency` | string | Fiat currency code |
| `symbol` | string | Cryptocurrency symbol (null for `NEW`) |
| `network` | string | Blockchain network (null for `NEW`) |
| `paymentAmount` | number | Crypto amount requested |

---

## Signature Verification

When `paymentUpdateWebhookSecret` is set, every outbound request includes an `X-SIGNATURE` header — an HMAC-SHA256 hex digest of the raw request body.

**Always verify this signature before acting on the webhook.**

### Verification — Node.js

```js
const crypto = require('crypto');

function verifyWebhook(rawBody, signature, secret) {
  const expected = crypto
    .createHmac('sha256', secret)
    .update(rawBody)           // rawBody must be the raw Buffer / string, not parsed JSON
    .digest('hex');
  return crypto.timingSafeEqual(
    Buffer.from(expected),
    Buffer.from(signature)
  );
}

// Express example (requires express.raw() or similar raw-body middleware)
app.post('/webhooks/crypay', express.raw({ type: 'application/json' }), (req, res) => {
  const sig = req.headers['x-signature'];
  if (!verifyWebhook(req.body, sig, process.env.CRYPAY_WEBHOOK_SECRET)) {
    return res.status(401).send('Invalid signature');
  }
  const event = JSON.parse(req.body);
  if (event.status === 'SUCCESS') {
    // fulfill order: event.reference
  }
  res.sendStatus(204);
});
```

### Verification — PHP

```php
function verifyWebhook(string $rawBody, string $signature, string $secret): bool {
    $expected = hash_hmac('sha256', $rawBody, $secret);
    return hash_equals($expected, strtolower($signature));
}

$rawBody  = file_get_contents('php://input');
$sig      = $_SERVER['HTTP_X_SIGNATURE'] ?? '';
$secret   = getenv('CRYPAY_WEBHOOK_SECRET');

if (!verifyWebhook($rawBody, $sig, $secret)) {
    http_response_code(401);
    exit('Invalid signature');
}

$event = json_decode($rawBody, true);
if ($event['status'] === 'SUCCESS') {
    // fulfill order: $event['reference']
}
http_response_code(204);
```

### Verification — Python

```python
import hmac
import hashlib

def verify_webhook(raw_body: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(
        secret.encode('utf-8'),
        raw_body,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature.lower())

# Flask example
from flask import Flask, request, abort
app = Flask(__name__)

@app.post('/webhooks/crypay')
def crypay_webhook():
    sig = request.headers.get('X-Signature', '')
    if not verify_webhook(request.get_data(), sig, os.environ['CRYPAY_WEBHOOK_SECRET']):
        abort(401)
    event = request.get_json()
    if event['status'] == 'SUCCESS':
        fulfill_order(event['reference'])
    return '', 204
```

---

## Important: Use Raw Body

Compute the HMAC over the **raw bytes** received on the wire — do not parse JSON first and re-serialize. Any change in whitespace or key ordering will produce a different digest and fail verification.

---

## Retry Policy

If your endpoint returns a non-2xx response or times out, Crypay retries the webhook:

| Attempt | Delay |
|---------|-------|
| 1 | Immediate |
| 2 | 1 minute |
| 3 | 5 minutes |
| 4 | 30 minutes |
| 5 | 2 hours |

After 5 failed attempts, no further retries are made. Check your server logs if you miss notifications.

---

## Best Practices

- **Respond quickly.** Return `204` (or `200`) immediately; do heavy processing asynchronously.
- **Make handlers idempotent.** The same event may be delivered more than once.
- **Check payment state yourself.** After receiving a webhook, optionally re-fetch `GET /api/payments/:shortId` to confirm state before fulfilling.
- **Only trust `SUCCESS` for fulfillment.** Do not ship on `WAITING_FOR_CONFIRMATION`.
- **Log raw payloads** during development to help debug signature mismatches.
