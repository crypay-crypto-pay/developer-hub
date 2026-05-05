# Authentication

Crypay supports two authentication methods for API access.

## API Key Authentication

For server-to-server integrations, use an API key.

### Generating a Key

1. Log in to [app.crypay.com](https://app.crypay.com)
2. Navigate to **Settings → API Keys → New Key**
3. Select the **PAYMENT** scope
4. Store both values securely — the `secretKey` is shown **only once**

### Key Components

| Field | Description |
|-------|-------------|
| `apiKey` | 32-character identifier — sent with every request |
| `secretKey` | 32-character HMAC signing secret — never sent over the network |

### Sending the API Key

Include the `X-API-KEY` header on every authenticated request:

```http
POST /api/payments HTTP/1.1
Host: app.crypay.com
X-API-KEY: your_api_key_here
Content-Type: application/json
```

### Request Signatures (optional)

For additional security, you can sign the request body with your `secretKey`. Add the computed signature in the `X-SIGNATURE` header.

**Algorithm:** HMAC-SHA256 over the raw JSON request body

```bash
# Example: compute signature for a request body
BODY='{"amount":19.99,"currency":"EUR","reference":"ORDER-001"}'
SECRET="your_secret_key"

SIGNATURE=$(echo -n "$BODY" | openssl dgst -sha256 -hmac "$SECRET" | awk '{print $2}')
```

```http
POST /api/payments HTTP/1.1
X-API-KEY: your_api_key_here
X-SIGNATURE: <hex-encoded HMAC-SHA256>
Content-Type: application/json

{"amount":19.99,"currency":"EUR","reference":"ORDER-001"}
```

**Important:** Compute the signature over the exact raw bytes you send. Any whitespace change invalidates the signature.

---

## JWT Authentication (Dashboard / POS)

For browser-based dashboard access, Crypay uses short-lived JWTs delivered via HTTP-only cookies. This is handled automatically by the web application and is not intended for server-to-server use.

---

## Security Best Practices

- **Never expose your `secretKey`** in client-side code, mobile apps, or public repositories.
- Use environment variables or a secrets manager (AWS Secrets Manager, Vault, etc.) to store credentials.
- Rotate your API key immediately if it is compromised (delete and create a new one).
- Use webhook secrets to verify Crypay's outbound notifications — see [Webhooks](webhooks.md).
- Enable **two-factor authentication (2FA)** on your Crypay account; key creation requires OTP confirmation.

---

## Key Scopes

| Scope | Permitted Operations |
|-------|---------------------|
| `PAYMENT` | Create payments, list payments, get payment details |

Additional scopes may be added in future API versions.

---

## Errors

| HTTP Status | Error Code | Cause |
|-------------|------------|-------|
| 401 | `API_KEY_MISSING` | `X-API-KEY` header absent |
| 401 | `INVALID_API_KEY` | Key not found or deleted |
| 401 | `SIGNATURE_MISSING` | `X-SIGNATURE` header required but absent |
| 401 | `INVALID_SIGNATURE` | Signature does not match |
