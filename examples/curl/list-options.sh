#!/usr/bin/env bash
# List available cryptocurrency options for a NEW payment.
#
# Usage:
#   export CRYPAY_API_KEY=your_api_key
#   ./list-options.sh abc123xyz456

set -euo pipefail

API_KEY="${CRYPAY_API_KEY:?Set CRYPAY_API_KEY environment variable}"
PAYMENT_ID="${1:?Pass payment ID as first argument}"
BASE_URL="${CRYPAY_BASE_URL:-https://api.crypay.com}"

curl -sf \
  "${BASE_URL}/payments/${PAYMENT_ID}/options?limit=50" \
  -H "X-API-KEY: ${API_KEY}" \
  | python3 -m json.tool 2>/dev/null
