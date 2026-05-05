#!/usr/bin/env bash
# Simulate an outbound Crypay webhook and verify its HMAC-SHA256 signature.
#
# Usage:
#   bash verify-webhook.sh

set -euo pipefail

WEBHOOK_SECRET="replace_with_a_strong_random_secret"

PAYLOAD=$(cat <<'JSON'
{
  "paymentId": "507f1f77bcf86cd799439011",
  "reference": "EXAMPLE-001",
  "status": "SUCCESS",
  "amount": 19.99,
  "currency": "EUR",
  "symbol": "BTC",
  "network": "bitcoin",
  "paymentAmount": 0.00050123
}
JSON
)

# Compute HMAC (strip trailing newline to match the exact bytes Crypay sends)
SIGNATURE=$(printf '%s' "${PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print $2}')

echo "Payload:"
echo "${PAYLOAD}"
echo ""
echo "X-SIGNATURE: ${SIGNATURE}"
echo ""

# Verify the signature (same logic your server should run)
VERIFY=$(printf '%s' "${PAYLOAD}" | openssl dgst -sha256 -hmac "${WEBHOOK_SECRET}" | awk '{print $2}')
if [[ "${SIGNATURE}" == "${VERIFY}" ]]; then
  echo "Signature OK — webhook would be accepted."
else
  echo "Signature MISMATCH — webhook would be rejected."
  exit 1
fi
