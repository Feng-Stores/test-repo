#!/bin/bash
set -euo pipefail

BASE_URL="${1:?Usage: smoke.sh <base-url>}"

echo "==> Health check"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/health")
[ "$STATUS" = "200" ] || { echo "FAIL: expected 200, got $STATUS"; exit 1; }
echo "PASS"

echo "==> Hello endpoint"
RESPONSE=$(curl -s "$BASE_URL/api/hello")
echo "$RESPONSE" | grep -q "message" || { echo "FAIL: unexpected response: $RESPONSE"; exit 1; }
echo "PASS"
