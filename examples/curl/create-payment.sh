#!/usr/bin/env bash
# Create a Crypay payment and print the checkout link.
#
# Usage:
#   export CRYPAY_API_KEY=your_api_key
#   chmod +x create-payment.sh
#   ./create-payment.sh

set -euo pipefail

API_KEY="${CRYPAY_API_KEY:?Set CRYPAY_API_KEY environment variable}"
BASE_URL="${CRYPAY_BASE_URL:-https://api.crypay.com}"

RESPONSE=$(curl -sf \
  -X POST "${BASE_URL}/payments" \
  -H "X-API-KEY: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 49.99,
    "currency": "EUR",
    "reference": "ORDER-001",
    "paymentTimeout": 3600,
    "successUrl": "https://yoursite.com/order/success",
    "failUrl":    "https://yoursite.com/order/cancelled"
  }')

echo "Payment created:"
echo "${RESPONSE}" | python3 -m json.tool 2>/dev/null || echo "${RESPONSE}"

LINK=$(echo "${RESPONSE}" | grep -o '"link":"[^"]*"' | cut -d'"' -f4)
echo ""
echo "Checkout link: ${LINK}"
