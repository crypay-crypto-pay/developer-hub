#!/usr/bin/env bash
# Create a Crypay payment via the REST API using curl.
#
# Usage:
#   export CRYPAY_API_KEY="your_api_key"
#   bash create-payment.sh
#
# Optional: set CRYPAY_API_URL to point at a different environment (e.g. staging).

set -euo pipefail

CRYPAY_API_URL="${CRYPAY_API_URL:-https://app.crypay.com/api}"
API_KEY="${CRYPAY_API_KEY:?Set CRYPAY_API_KEY before running this script}"

# ── Request body ────────────────────────────────────────────────────────────────
BODY=$(cat <<'JSON'
{
  "amount": 19.99,
  "currency": "EUR",
  "reference": "EXAMPLE-001",
  "description": "Test payment from curl example",
  "successUrl": "https://yourshop.example.com/success",
  "failUrl":    "https://yourshop.example.com/cancel",
  "paymentUpdateWebhook":       "https://yourshop.example.com/webhooks/crypay",
  "paymentUpdateWebhookSecret": "replace_with_a_strong_random_secret"
}
JSON
)

# ── Create payment ───────────────────────────────────────────────────────────────
echo "Creating payment..."
RESPONSE=$(curl -s -X POST "${CRYPAY_API_URL}/payments" \
  -H "X-API-KEY: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${BODY}")

echo "${RESPONSE}" | python3 -m json.tool 2>/dev/null || echo "${RESPONSE}"

# ── Extract short ID ─────────────────────────────────────────────────────────────
SHORT_ID=$(echo "${RESPONSE}" | python3 -c "import sys,json; print(json.load(sys.stdin)['shortId'])" 2>/dev/null || true)

if [[ -z "${SHORT_ID}" ]]; then
  echo ""
  echo "Error: could not extract shortId — check the response above."
  exit 1
fi

echo ""
echo "Payment created: ${SHORT_ID}"
echo "Payment URL:     https://app.crypay.com/pay/${SHORT_ID}"
echo ""

# ── Poll for options ─────────────────────────────────────────────────────────────
echo "Available payment options:"
curl -s "${CRYPAY_API_URL}/payments/${SHORT_ID}/options" \
  | python3 -c "
import sys, json
opts = json.load(sys.stdin)
for o in opts[:5]:
    print(f\"  {o['symbol']:6s} ({o['network']:12s})  {o['paymentAmount']:>14.8f}  @ {o['exchangeRate']:,.2f} {o['baseSymbol']}/coin\")
"
