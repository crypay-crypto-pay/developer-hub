# Crypay Developer Hub

Accept cryptocurrency payments with a single API call.

**[crypay.com](https://crypay.com)** · [API Docs](#api-documentation) · [Examples](#examples) · [Eshop Modules](#eshop-modules)

---

## Quick Start

```bash
curl -X POST https://api.crypay.com/payments \
  -H "X-API-KEY: your_api_key" \
  -H "Content-Type: application/json" \
  -d '{"amount": 49.99, "currency": "EUR", "reference": "ORDER-001"}'
# → {"id": "abc123xyz456", "link": "https://pay.crypay.com/abc123xyz456"}
```

Redirect your customer to `link`. Crypay handles crypto selection, address generation, confirmation tracking, and webhook delivery.

---

## API Documentation

| Document | Description |
|---|---|
| [Quickstart](docs/api/quickstart.md) | Create your first payment in 5 minutes |
| [Authentication](docs/api/authentication.md) | API key setup and HMAC signing |
| [Payments](docs/api/payments.md) | Full payment endpoint reference |
| [Webhooks](docs/api/webhooks.md) | Receive payment status updates |
| [Error Codes](docs/api/errors.md) | Error codes and recovery guidance |
| [OpenAPI Schema](docs/api/openapi.yaml) | Machine-readable spec (OpenAPI 3.0) |

### Render the OpenAPI spec locally

```bash
npx @redocly/cli preview-docs docs/api/openapi.yaml
# Open http://localhost:8080
```

Or use the hosted version: **[crypay.com/developers](https://crypay.com/developers)**

---

## Examples

| Example | Directory |
|---|---|
| curl (bash) | [examples/curl/](examples/curl/) |
| Node.js (axios) | [examples/node/](examples/node/) *(Phase 2)* |
| Python (requests) | [examples/python/](examples/python/) *(Phase 2)* |
| PHP (Guzzle) | [examples/php/](examples/php/) *(Phase 2)* |

---

## Eshop Modules

| Module | Directory | Status |
|---|---|---|
| WooCommerce | [modules/woocommerce/](modules/woocommerce/) | Phase 3 |
| Shopify | [modules/shopify/](modules/shopify/) | Phase 4 |
| PrestaShop | [modules/prestashop/](modules/prestashop/) | Phase 4 |
| Magento | [modules/magento/](modules/magento/) | Phase 4 |

---

## Supported Cryptocurrencies

Crypay supports BTC (mainnet + Lightning), ETH, and other major networks. Use `GET /payments/{id}/options` to list all options available for a payment.

**Supported fiat currencies:** EUR, USD, CZK, GBP, HUF

---

## Support

- Email: support@crypay.com
- Docs: [crypay.com/developers](https://crypay.com/developers)
- Issues: [github.com/crypay-crypto-pay/developer-hub/issues](https://github.com/crypay-crypto-pay/developer-hub/issues)
