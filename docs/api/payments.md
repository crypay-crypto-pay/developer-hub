# Payments API Reference

**Base path:** `/api/payments`

---

## Create Payment

```
POST /api/payments
```

Creates a new payment request. Returns a `shortId` you can use to redirect the customer to the hosted payment page.

**Authentication:** API Key (`PAYMENT` scope) or JWT

### Request Body

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `amount` | number | Yes | Amount to charge (e.g. `19.99`) |
| `currency` | string | Yes | Fiat currency code (`EUR`, `USD`, `CZK`, …) |
| `reference` | string | No | Your internal order ID |
| `description` | string | No | Free-text description shown on the payment page |
| `successUrl` | string | No | Redirect URL after successful payment |
| `failUrl` | string | No | Redirect URL if the customer cancels or payment expires |
| `paymentUpdateWebhook` | string | No | URL to receive payment state change events |
| `paymentUpdateWebhookSecret` | string | No | Secret used to sign outbound webhook payloads |
| `selectionTimeout` | integer | No | Seconds the customer has to pick a coin (default: `600`) |
| `paymentTimeout` | integer | No | Seconds the payment address stays valid (default: `3600`) |
| `language` | string | No | UI language (`EN`, `SK`, …) |
| `multi` | boolean | No | Allow payment to be used multiple times |
| `options` | array | No | Pre-select which cryptocurrencies to offer |
| `test` | boolean | No | Mark as test payment (only visible in test mode) |
| `merchant` | object | No | Override merchant details for this payment |
| `customer` | object | No | Attach customer info (name, email, registration number) |

#### `options` item

```json
{ "symbol": "BTC", "network": "bitcoin" }
```

#### `merchant` object

```json
{
  "name": "Acme Corp",
  "registrationNumber": "12345678",
  "address": "123 Main St, Prague",
  "email": "billing@acme.com"
}
```

#### `customer` object

```json
{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "registrationNumber": null
}
```

### Example Request

```bash
curl -X POST https://app.crypay.com/api/payments \
  -H "X-API-KEY: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 49.90,
    "currency": "EUR",
    "reference": "INV-2026-042",
    "description": "Order #42 — Running shoes",
    "successUrl": "https://shop.example.com/success",
    "failUrl": "https://shop.example.com/cancel",
    "paymentUpdateWebhook": "https://shop.example.com/webhooks/crypay",
    "paymentUpdateWebhookSecret": "whs_super_secret_value"
  }'
```

### Response — `NEW` payment

```json
{
  "id": "507f1f77bcf86cd799439011",
  "userId": "507f1f77bcf86cd799439012",
  "shortId": "abc123de",
  "state": "NEW",
  "created": "2026-05-05T10:00:00.000Z",
  "amount": 49.90,
  "currency": "EUR",
  "currencyDecimals": 2,
  "reference": "INV-2026-042",
  "description": "Order #42 — Running shoes",
  "settlementOption": "DIRECT",
  "transactions": [],
  "offered": null,
  "started": null,
  "symbolDecimals": null
}
```

Redirect the customer to `https://app.crypay.com/pay/{shortId}`.

---

## Get Payment

```
GET /api/payments/:shortId
```

Returns the full payment object. No authentication required — use this to poll for state changes from a frontend.

### Response — `WAITING_FOR_PAYMENT`

```json
{
  "id": "507f1f77bcf86cd799439011",
  "shortId": "abc123de",
  "state": "WAITING_FOR_PAYMENT",
  "amount": 49.90,
  "currency": "EUR",
  "symbol": "BTC",
  "network": "bitcoin",
  "address": "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq",
  "paymentAmount": 0.00125000,
  "exchangeRate": 39920,
  "fee": 0.00001,
  "symbolDecimals": 8,
  "memo": null,
  "offered": "2026-05-05T10:02:00.000Z",
  "started": "2026-05-05T10:05:00.000Z",
  "transactions": []
}
```

---

## List Payments

```
GET /api/payments
```

Returns a paginated list of payments belonging to the authenticated merchant.

**Authentication:** API Key (`PAYMENT` scope) or JWT

### Query Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `limit` | integer | `25` | Results per page (1–50) |
| `offset` | integer | `0` | Pagination offset |
| `order` | string | `created:desc` | Sort field and direction. Fields: `created`, `reference`, `amount`, `state`, `paymentAmount` |
| `term` | string | — | Full-text search across reference, short ID, description |
| `dateFrom` | string | — | Filter from date (`YYYY-MM-DD`) |
| `dateTo` | string | — | Filter to date (`YYYY-MM-DD`) |
| `states` | string | — | Comma-separated states: `NEW,WAITING_FOR_PAYMENT,WAITING_FOR_CONFIRMATION,SUCCESS,EXPIRED` |
| `currencies` | string | — | Comma-separated fiat currencies: `EUR,USD` |
| `symbols` | string | — | Comma-separated crypto symbols: `BTC,ETH` |
| `ids` | string | — | Comma-separated `shortId` values |
| `test` | boolean | — | `true` to show only test payments |

### Example

```bash
curl "https://app.crypay.com/api/payments?states=SUCCESS&dateFrom=2026-05-01&limit=10" \
  -H "X-API-KEY: YOUR_API_KEY"
```

---

## Get Payment Options

```
GET /api/payments/:shortId/options
```

Lists available cryptocurrencies for a `NEW` payment, with current exchange rates.

**Authentication:** None

### Query Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `limit` | `25` | Options per page (1–50) |
| `afterSymbol` | — | Cursor for next page (pass last `symbol` from previous response) |

### Response

```json
[
  {
    "symbol": "BTC",
    "network": "bitcoin",
    "decimals": 8,
    "baseSymbol": "EUR",
    "paymentAmount": 0.00125000,
    "exchangeRate": 39920,
    "originalExchangeRate": 39920,
    "fee": 0.00001,
    "disabled": false
  },
  {
    "symbol": "ETH",
    "network": "ethereum",
    "decimals": 18,
    "baseSymbol": "EUR",
    "paymentAmount": 0.01640000,
    "exchangeRate": 3043,
    "originalExchangeRate": 3043,
    "fee": 0.0005,
    "disabled": false
  }
]
```

---

## Select Payment Option

```
POST /api/payments/:shortId/set-option
```

Assigns a cryptocurrency to the payment and generates a deposit address. The state moves to `WAITING_FOR_PAYMENT`.

**Authentication:** None (called from the customer's browser)

### Request Body

```json
{
  "symbol": "BTC",
  "network": "bitcoin"
}
```

### Response

`204 No Content`

---

## Payment States

| State | Meaning | Terminal |
|-------|---------|----------|
| `NEW` | Created, awaiting option selection | No |
| `WAITING_FOR_PAYMENT` | Address assigned, awaiting transaction | No |
| `WAITING_FOR_CONFIRMATION` | Transaction detected, awaiting confirmations | No |
| `SUCCESS` | Fully confirmed | Yes |
| `EXPIRED` | Timed out before payment arrived | Yes |

---

## Supported Symbols

```
GET /api/symbols
```

Returns all symbols supported as payment options.

```bash
curl https://app.crypay.com/api/symbols
```

```json
[
  {
    "code": "BTC",
    "decimals": 8,
    "type": "CRYPTO",
    "networks": [
      {
        "code": "bitcoin",
        "type": "MAINNET",
        "native": true,
        "useMemo": false,
        "contractAddress": null
      }
    ]
  }
]
```
