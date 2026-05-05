# Authentication

Crypay uses API key authentication for all merchant-facing endpoints.

---

## API Key

Every request must include your API key in the `X-API-KEY` header:

```
X-API-KEY: your_32_character_api_key
```

Obtain your API key from the **Crypay merchant dashboard** → Settings → API Keys.

**Example:**

```bash
curl https://api.crypay.com/payments \
  -H "X-API-KEY: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
```

---

## API Key + Secret

When you create an API key, the dashboard also shows a **Secret Key**. The secret is used to:

- Sign outgoing webhook payloads (Crypay → your server)
- Optionally verify inbound requests from Crypay (extra defence-in-depth)

**Never expose your Secret Key** in client-side code or version control.

---

## HMAC Webhook Signature

When you provide a `paymentUpdateWebhookSecret` on payment creation, Crypay signs every webhook delivery with an HMAC-SHA256 digest of the raw request body.

**Header sent by Crypay:**
```
X-SIGNATURE: 3a7b9c2d...  (hex string)
```

**Verification — Node.js:**

```javascript
const crypto = require('crypto');

function verifyWebhook(req, secret) {
  const rawBody = req.rawBody; // must be the raw Buffer/string, not parsed JSON
  const signature = req.headers['x-signature'] ?? '';

  const expected = crypto
    .createHmac('sha256', Buffer.from(secret, 'utf-8'))
    .update(Buffer.from(rawBody, 'utf-8'))
    .digest('hex');

  return expected.toLowerCase() === signature.toLowerCase();
}
```

**Verification — Python:**

```python
import hmac, hashlib

def verify_webhook(raw_body: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(
        secret.encode('utf-8'),
        raw_body,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature.lower())
```

**Verification — PHP:**

```php
function verifyWebhook(string $rawBody, string $signature, string $secret): bool {
    $expected = hash_hmac('sha256', $rawBody, $secret);
    return hash_equals($expected, strtolower($signature));
}
```

---

## Error Responses

| HTTP | Code | Cause |
|---|---|---|
| 401 | `API_KEY_MISSING` | `X-API-KEY` header absent |
| 401 | `INVALID_API_KEY` | Key format invalid |
| 401 | `KEY_NOT_FOUND` | Key not found or revoked |
| 403 | `SIGNATURE_MISSING` | `X-SIGNATURE` required but absent |
| 403 | `INVALID_SIGNATURE` | HMAC mismatch |

---

## Security Best Practices

- Rotate your API key immediately if you suspect it has been compromised.
- Always verify the `X-SIGNATURE` header before fulfilling orders based on webhook data.
- Use `https://` endpoints exclusively — never send keys over plain HTTP.
- Store keys in environment variables or a secrets manager, not in source code.
