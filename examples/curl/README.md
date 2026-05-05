# cURL Examples

Standalone bash scripts for common Crypay API operations.

## Requirements

- `bash` 4+
- `curl`
- `openssl`
- `python3` (for JSON pretty-printing)

## Scripts

| Script | Description |
|--------|-------------|
| `create-payment.sh` | Create a payment and print the customer payment URL |
| `verify-webhook.sh` | Simulate a Crypay webhook and verify its HMAC signature |

## Quick Start

```bash
export CRYPAY_API_KEY="your_api_key_here"
bash create-payment.sh
```

Expected output:

```
Creating payment...
{
    "shortId": "abc123de",
    "state": "NEW",
    ...
}

Payment created: abc123de
Payment URL:     https://app.crypay.com/pay/abc123de

Available payment options:
  BTC    (bitcoin     )    0.00050000  @ 39,920.00 EUR/coin
  ETH    (ethereum    )    0.00660000  @  3,029.00 EUR/coin
```

## Test Mode

Run in test mode by using an API key created while your account has **Test Mode** enabled in Settings. Test payments never touch real blockchains.
