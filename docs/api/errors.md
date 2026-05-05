# Errors

All Crypay API errors follow a consistent JSON structure.

## Error Response Format

```json
{
  "error": "Human-readable message",
  "status": 400,
  "details": {
    "reason": "ERROR_CODE"
  }
}
```

## HTTP Status Codes

| Code | Meaning |
|------|---------|
| `200` | Success — response body present |
| `201` | Created — new resource returned |
| `204` | Success — no response body |
| `400` | Bad Request — invalid input |
| `401` | Unauthorized — missing or invalid credentials |
| `403` | Forbidden — insufficient permissions |
| `404` | Not Found — resource does not exist |
| `429` | Too Many Requests — rate limit reached |
| `500` | Internal Server Error |

---

## Error Codes

### Authentication

| Code | Status | Description | Recovery |
|------|--------|-------------|----------|
| `API_KEY_MISSING` | 401 | `X-API-KEY` header absent | Add the `X-API-KEY` header |
| `INVALID_API_KEY` | 401 | Key not found or deleted | Check the key or generate a new one |
| `SIGNATURE_MISSING` | 401 | Request requires `X-SIGNATURE` but header is absent | Compute and send the HMAC signature |
| `INVALID_SIGNATURE` | 401 | HMAC digest does not match | Verify you're signing the raw body with the correct secret |
| `JWT_TOKEN_MISSING` | 401 | Session token absent | Re-authenticate |
| `JWT_TOKEN_EXPIRED` | 401 | Session token expired | Refresh the session |
| `INVALID_JWT_TOKEN` | 401 | Token malformed | Re-authenticate |
| `INVALIDATED_JWT_TOKEN` | 401 | Token was explicitly invalidated | Re-authenticate |
| `MISSING_AUTHORIZATION` | 401 | No auth method supplied | Add `X-API-KEY` or a valid session |

### User / Account

| Code | Status | Description | Recovery |
|------|--------|-------------|----------|
| `USER_NOT_FOUND` | 404 | Account does not exist | Check the email address |
| `USER_ALREADY_EXISTS` | 400 | Email already registered | Log in or use password reset |
| `INVALID_PASSWORD` | 401 | Password incorrect | Check credentials |
| `INVALID_ACCOUNT_STATE` | 400 | Account not activated or suspended | Activate via email link |
| `WEAK_PASSWORD` | 400 | Password does not meet requirements | Use ≥8 characters with mixed case + numbers |

### Two-Factor Authentication

| Code | Status | Description | Recovery |
|------|--------|-------------|----------|
| `OTP_INVALID` | 401 | OTP code incorrect | Check TOTP app clock sync |
| `OTP_MISSING` | 401 | OTP required but not provided | Include the OTP header |
| `OTP_NOT_ENABLED` | 400 | OTP operation requires 2FA to be on | Enable 2FA in account settings |
| `OTP_ALREADY_ENABLED` | 400 | Trying to enable already-enabled 2FA | 2FA is already active |
| `OTP_RECOVERY_INVALID` | 401 | Recovery code invalid or already used | Use a different recovery code |

### API Keys

| Code | Status | Description | Recovery |
|------|--------|-------------|----------|
| `KEY_NOT_FOUND` | 404 | API key ID not found | Check the key ID |
| `INVALID_KEY_SCOPES` | 400 | Requested scope not allowed | Use a valid scope (`PAYMENT`) |

### Payments

| Code | Status | Description | Recovery |
|------|--------|-------------|----------|
| `PAYMENT_NOT_FOUND` | 404 | Payment with given `shortId` does not exist | Verify the ID |
| `INVALID_PAYMENT_STATE` | 400 | Operation not allowed in current state | Check current state before calling |
| `INVALID_CURRENCY` | 400 | Currency code not recognised | Use a supported ISO 4217 code |
| `INVALID_SYMBOL` | 400 | Crypto symbol not supported | Check `/api/symbols` for supported values |
| `EXCHANGE_RATE_NOT_FOUND` | 503 | No rate available for this pair | Retry shortly; rates refresh frequently |
| `INVALID_PAYMENT_OPTION` | 400 | Symbol/network combination not valid for this payment | Check available options via `GET /payments/:id/options` |
| `GATEWAY_ERROR` | 502 | Upstream blockchain gateway error | Retry with exponential backoff |
| `MISSING_MEMO` | 400 | Network requires a memo/tag field | Include `memo` when sending to this network |
| `PAYMENT_EXPIRED` | 400 | Payment window has closed | Create a new payment |
| `MAX_PAYMENTS_LIMIT` | 429 | Too many open payments | Wait for existing payments to resolve |

### Settlements

| Code | Status | Description | Recovery |
|------|--------|-------------|----------|
| `INVALID_ADDRESS` | 400 | Wallet address failed validation | Verify the address for the target network |
| `WALLET_ALREADY_EXISTS` | 400 | Address already registered | Use existing wallet or remove it first |
| `WALLET_NOT_FOUND` | 404 | Wallet address not registered | Add the wallet in settlement settings |
| `UNSUPPORTED_NETWORK` | 400 | Network not available for settlement | Check supported settlement networks |
| `INVALID_PAYMENTS_LIST` | 400 | One or more payment IDs invalid | Verify all `shortId` values |
| `PAYMENT_ALREADY_IN_SETTLEMENT` | 400 | Payment already included in a settlement batch | Each payment can only be settled once |
| `INVALID_SETTLEMENT_CONFIG` | 400 | Settlement configuration incomplete or invalid | Review your settlement settings |

### POS / Devices

| Code | Status | Description | Recovery |
|------|--------|-------------|----------|
| `POS_DEVICE_NOT_FOUND` | 404 | Device ID not found | Check the device ID |
| `POS_INVALID_REGISTRATION_CODE` | 400 | Registration code incorrect or expired | Generate a new code in the dashboard |
| `POS_INVALID_PIN` | 401 | PIN incorrect | Retry; 5 wrong attempts lock the device |
| `POS_DEVICE_LOCKED` | 403 | Device locked after too many failed PINs | Unlock from the merchant dashboard |

### Other

| Code | Status | Description |
|------|--------|-------------|
| `CAPTCHA_MISSING` | 400 | reCAPTCHA token absent on a public form endpoint |
| `CAPTCHA_FAILED` | 400 | reCAPTCHA verification failed |
| `DNS_ERROR` | 400 | DNS resolution failed for a provided URL |
| `EMPTY_DATA` | 400 | Required field(s) missing |

---

## Rate Limits

The API enforces per-IP and per-key rate limits. When exceeded, you receive:

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 30
```

Back off and retry after the `Retry-After` interval.

---

## Handling Errors in Code

```js
const response = await fetch('https://app.crypay.com/api/payments', { ... });
if (!response.ok) {
  const err = await response.json();
  // err.details.reason === 'INVALID_CURRENCY'
  switch (err.details?.reason) {
    case 'EXCHANGE_RATE_NOT_FOUND':
      // retry after 5 seconds
      break;
    case 'INVALID_API_KEY':
      // log alert — credentials compromised or rotated
      break;
    default:
      throw new Error(`Crypay error: ${err.error}`);
  }
}
```
