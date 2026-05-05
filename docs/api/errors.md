# Error Codes

All Crypay API errors follow a consistent JSON format:

```json
{
  "error": "Human-readable message",
  "status": 400,
  "details": {
    "reason": "MACHINE_READABLE_CODE"
  }
}
```

Some errors include additional fields inside `details` (e.g. `"limit": 100`).

---

## Authentication Errors

| HTTP | `reason` | Description | Recovery |
|---|---|---|---|
| 401 | `API_KEY_MISSING` | `X-API-KEY` header is absent | Add the header |
| 401 | `INVALID_API_KEY` | Key format is invalid | Check for extra spaces or truncation |
| 401 | `KEY_NOT_FOUND` | Key does not exist or has been revoked | Generate a new key in the dashboard |
| 403 | `SIGNATURE_MISSING` | `X-SIGNATURE` was required but not sent | Sign the request body with your secret |
| 403 | `INVALID_SIGNATURE` | HMAC mismatch | Ensure you sign the raw body, not re-serialised JSON |

---

## Payment Errors

| HTTP | `reason` | Description | Recovery |
|---|---|---|---|
| 400 | `INVALID_CURRENCY` | Currency not supported or not available | Use `EUR`, `USD`, `CZK`, `GBP`, or `HUF` |
| 400 | `MAX_PAYMENTS_LIMIT` | You have 100+ concurrent active payments | Wait for some to expire or close them |
| 400 | `INVALID_PAYMENT_STATE` | Operation not allowed in current state | Check `state` via `GET /payments/{id}` first |
| 400 | `PAYMENT_EXPIRED` | Payment window has passed | Create a new payment |
| 400 | `INVALID_PAYMENT_OPTION` | Symbol/network combination not available | Call `GET /payments/{id}/options` for valid options |
| 400 | `INVALID_SYMBOL` | Cryptocurrency symbol not recognised | Check symbol against the options list |
| 400 | `INVALID_ADDRESS` | Provided address is malformed | Verify the deposit address format |
| 400 | `MISSING_MEMO` | Network requires a memo/tag but none provided | Include the `memo` field |
| 404 | `PAYMENT_NOT_FOUND` | Payment ID does not exist | Check the ID; payments are case-sensitive |

---

## Exchange Rate Errors

| HTTP | `reason` | Description | Recovery |
|---|---|---|---|
| 400 | `EXCHANGE_RATE_NOT_FOUND` | No rate available for this pair | Try again in a few seconds; rates refresh frequently |

---

## HTTP Status Summary

| HTTP | Meaning |
|---|---|
| 200 | OK |
| 201 | Resource created |
| 204 | Success, no body |
| 400 | Bad request — check `details.reason` |
| 401 | Authentication failed |
| 403 | Authorisation failed |
| 404 | Resource not found |
| 500 | Internal server error — contact support |

---

## Handling Errors in Code

### Node.js

```javascript
const response = await fetch('https://api.crypay.com/payments', {
  method: 'POST',
  headers: { 'X-API-KEY': apiKey, 'Content-Type': 'application/json' },
  body: JSON.stringify({ amount: 10, currency: 'EUR', reference: 'ORD-1' }),
});

if (!response.ok) {
  const err = await response.json();
  console.error(`Crypay error [${err.status}] ${err.details?.reason}: ${err.error}`);
  // e.g. "Crypay error [400] INVALID_CURRENCY: Currency not supported"
}
```

### Python

```python
import requests

r = requests.post(
    'https://api.crypay.com/payments',
    headers={'X-API-KEY': api_key},
    json={'amount': 10, 'currency': 'EUR', 'reference': 'ORD-1'},
)
if not r.ok:
    err = r.json()
    print(f"Crypay error [{err['status']}] {err['details']['reason']}: {err['error']}")
```
