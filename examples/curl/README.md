# curl Examples

Standalone bash scripts using curl. No dependencies beyond `bash`, `curl`, and `python3` (for JSON pretty-printing).

## Setup

```bash
export CRYPAY_API_KEY=your_api_key
# For testnet: export CRYPAY_BASE_URL=https://api.crypay.com
```

## Scripts

| Script | Description |
|---|---|
| `create-payment.sh` | Create a payment and print the checkout link |
| `get-payment.sh <id>` | Fetch current payment status |
| `list-options.sh <id>` | List available cryptocurrencies for a NEW payment |

## Example

```bash
# 1. Create a payment
./create-payment.sh
# → Checkout link: https://pay.crypay.com/abc123xyz456

# 2. Check its status
./get-payment.sh abc123xyz456

# 3. See available crypto options (while state is NEW)
./list-options.sh abc123xyz456
```
