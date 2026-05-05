# Payments — API Reference

Base URL: `https://api.crypay.com`

All endpoints require the `X-API-KEY` header. See [Authentication](authentication.md).

---

## Create Payment

```
POST /payments
```

Creates a new payment session. Returns a hosted payment link to redirect your customer to.

### Request Headers

| Header | Required | Value |
|---|---|---|
| `X-API-KEY` | Yes | Your merchant API key |
| `Content-Type` | Yes | `application/json` |

### Request Body

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `amount` | number | Yes | — | Payment amount (must be > 0) |
| `currency` | string | Yes | — | Fiat currency: `EUR`, `USD`, `CZK`, `GBP`, `HUF` |
| `reference` | string | Yes | — | Your order/invoice reference |
| `paymentTimeout` | number | No | `3600` | Seconds the customer has to pay after selecting a crypto |
| `selectionTimeout` | number | No | `null` | Seconds to select a crypto (null = no limit) |
| `successUrl` | string | No | `null` | Redirect URL on successful payment |
| `failUrl` | string | No | `null` | Redirect URL on expired/failed payment |
| `language` | string | No | `null` | UI language: `SK`, `EN` |
| `multi` | boolean | No | `false` | Allow multiple payment options simultaneously |
| `options` | array | No | `[]` | Restrict to specific crypto options (see below) |
| `test` | boolean | No | `false` | Use testnet networks only |
| `description` | string | No | `null` | Free-text payment description |
| `merchant` | object | No | — | Issuer details (see below) |
| `customer` | object | No | — | Customer details (see below) |
| `paymentUpdateWebhook` | string | No | `null` | URL to POST status updates to |
| `paymentUpdateWebhookSecret` | string | No | `null` | HMAC secret for signing webhook payloads |

#### `options` item

```json
{ "symbol": "BTC", "network": "BITCOIN" }
```

#### `merchant` object

```json
{
  "name": "Acme s.r.o.",
  "registrationNumber": "12345678",
  "address": "Hlavná 1, 811 01 Bratislava"
}
```

#### `customer` object

```json
{
  "name": "Ján Novák",
  "registrationNumber": "87654321",
  "email": "jan@example.com"
}
```

### Response — 201 Created

```json
{
  "id": "abc123xyz456",
  "link": "https://pay.crypay.com/abc123xyz456"
}
```

Redirect the customer to `link`.

### Errors

| HTTP | Code | Description |
|---|---|---|
| 400 | `INVALID_CURRENCY` | Currency not supported |
| 400 | `MAX_PAYMENTS_LIMIT` | Too many concurrent active payments (limit: 100) |

---

## Get Payment

```
GET /payments/{id}
```

Returns the current state of a payment.

### Response — 200 OK

```json
{
  "id": "abc123xyz456",
  "state": "WAITING_FOR_PAYMENT",
  "amount": 49.99,
  "currency": "EUR",
  "currencyDecimals": 2,
  "reference": "ORDER-001",
  "created": "2026-05-05T10:00:00.000Z",
  "offered": "2026-05-05T10:02:00.000Z",
  "started": "2026-05-05T10:05:00.000Z",
  "language": "EN",
  "selectionTimeout": null,
  "paymentTimeout": 3600,
  "test": false,
  "redirectUrl": null,
  "description": null,
  "settlementOption": "DIRECT",
  "link": "https://pay.crypay.com/abc123xyz456",
  "merchant": null,
  "customer": null,
  "address": "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq",
  "symbol": "BTC",
  "symbolDecimals": 8,
  "network": "BITCOIN",
  "paymentAmount": 0.00078,
  "baseSymbol": "EUR",
  "memo": null,
  "paid": 0,
  "paidConfirmed": 0,
  "paidUnconfirmed": 0,
  "overpaid": 0,
  "remaining": 0.00078
}
```

### Payment States

| State | Description |
|---|---|
| `NEW` | Created, waiting for customer to select a cryptocurrency |
| `WAITING_FOR_PAYMENT` | Crypto selected, address assigned, waiting for on-chain transaction |
| `WAITING_FOR_CONFIRMATION` | Transaction seen on-chain, waiting for confirmations |
| `SUCCESS` | Payment confirmed — fulfil the order |
| `EXPIRED` | Payment timed out before completion |

### Errors

| HTTP | Code | Description |
|---|---|---|
| 404 | `PAYMENT_NOT_FOUND` | Payment ID does not exist |

---

## List Payment Options

```
GET /payments/{id}/options
```

Returns available cryptocurrencies and their equivalent amounts for a `NEW` payment.

### Query Parameters

| Parameter | Default | Description |
|---|---|---|
| `limit` | `25` | Items per page (1–50) |
| `afterSymbol` | — | Cursor for next page |

### Response — 200 OK

```json
{
  "totalCount": 12,
  "items": [
    {
      "symbol": "BTC",
      "network": "BITCOIN",
      "decimals": 8,
      "baseSymbol": "EUR",
      "paymentAmount": 0.00078,
      "exchangeRate": 64102.5,
      "originalExchangeRate": 64050.0
    }
  ]
}
```

`exchangeRate` includes the Crypay processing fee; `originalExchangeRate` does not.

### Errors

| HTTP | Code | Description |
|---|---|---|
| 404 | `PAYMENT_NOT_FOUND` | Payment not found |
| 400 | `INVALID_PAYMENT_STATE` | Payment not in `NEW` state |
| 400 | `PAYMENT_EXPIRED` | Selection timeout exceeded |

---

## Select Payment Option

```
POST /payments/{id}/set-option
```

Locks in the cryptocurrency the customer chose. After this call, a deposit address is assigned and the payment moves to `WAITING_FOR_PAYMENT`.

### Request Body

```json
{
  "symbol": "BTC",
  "network": "BITCOIN"
}
```

### Response — 204 No Content

### Errors

| HTTP | Code | Description |
|---|---|---|
| 404 | `PAYMENT_NOT_FOUND` | Payment not found |
| 400 | `INVALID_PAYMENT_STATE` | Payment not in `NEW` state |
| 400 | `INVALID_PAYMENT_OPTION` | Symbol/network combination not valid |
| 400 | `PAYMENT_EXPIRED` | Selection timeout exceeded |

---

## List My Payments

```
GET /payments
```

Returns a paginated list of your payments.

### Query Parameters

| Parameter | Default | Description |
|---|---|---|
| `limit` | `25` | Items per page (1–50) |
| `offset` | `0` | Pagination offset |
| `order` | `created:desc` | Sort: `created|reference|amount|state` + `:asc|:desc` |
| `term` | — | Search term |
| `dateFrom` | — | `YYYY-MM-DD` start date |
| `dateTo` | — | `YYYY-MM-DD` end date |
| `states` | — | Comma-separated states |
| `currencies` | — | Comma-separated fiat currencies |
| `test` | — | `true` or `false` |

### Response — 200 OK

```json
{
  "totalCount": 42,
  "items": [/* payment objects */]
}
```
