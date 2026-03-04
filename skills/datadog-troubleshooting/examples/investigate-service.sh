#!/usr/bin/env bash
# Example: Investigate a service's health in Datadog
#
# AUTOMATED: This script is automatically called by run-investigation.sh for service health investigations.
# It can also be run directly for manual investigation.
#
# Usage: SERVICE=payment-api ENV=prod DD_API_KEY=xxx DD_APP_KEY=yyy bash investigate-service.sh
# Example: SERVICE=payment-api ENV=prod MINUTES=120 bash investigate-service.sh
#
# Required environment variables:
#   SERVICE: Service name (as tagged in Datadog)
#   ENV: Environment name (default: prod)
#   DD_API_KEY: Datadog API key
#   DD_APP_KEY: Datadog application key
#   MINUTES: Time window in minutes (default: 60)

set -euo pipefail

SERVICE="${SERVICE:?Set SERVICE env var}"
ENV="${ENV:-prod}"
DD_SITE="${DD_SITE:-datadoghq.com}"
DD_API_KEY="${DD_API_KEY:?Set DD_API_KEY env var}"
DD_APP_KEY="${DD_APP_KEY:?Set DD_APP_KEY env var}"
MINUTES="${MINUTES:-60}"

# Calculate time window
FROM=$(date -u -d "${MINUTES} minutes ago" +%s 2>/dev/null || date -u -v-${MINUTES}M +%s)
TO=$(date -u +%s)
FROM_ISO=$(date -u -d "${MINUTES} minutes ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-${MINUTES}M +%Y-%m-%dT%H:%M:%SZ)
TO_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

BASE_URL="https://api.${DD_SITE}"
AUTH_HEADERS=(-H "DD-API-KEY: ${DD_API_KEY}" -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" -H "Content-Type: application/json")

echo "=== Datadog Service Investigation: ${SERVICE} [${ENV}] (last ${MINUTES} min) ==="
echo ""

echo "=== Triggered Monitors for ${SERVICE} ==="
curl -s "${BASE_URL}/api/v1/monitor/search?query=tag:service:${SERVICE}" \
  "${AUTH_HEADERS[@]}" | \
  jq -r '.monitors[] | select(.status == "Alert" or .status == "No Data") | "[\(.status)] \(.name)"' 2>/dev/null \
  || echo "No monitors found or jq not available"

echo ""
echo "=== Recent Error Logs (last ${MINUTES} min) ==="
curl -s -X POST "${BASE_URL}/api/v2/logs/events/search" \
  "${AUTH_HEADERS[@]}" \
  -d "{
    \"filter\": {
      \"query\": \"service:${SERVICE} env:${ENV} status:error\",
      \"from\": \"${FROM_ISO}\",
      \"to\": \"${TO_ISO}\"
    },
    \"sort\": \"-timestamp\",
    \"page\": {\"limit\": 10}
  }" | jq -r '.data[]?.attributes | "[\(.timestamp)] \(.message)"' 2>/dev/null \
  || echo "No error logs found"

echo ""
echo "=== Error Count by Status (last ${MINUTES} min) ==="
curl -s -X POST "${BASE_URL}/api/v2/logs/analytics/aggregate" \
  "${AUTH_HEADERS[@]}" \
  -d "{
    \"compute\": [{\"aggregation\": \"count\", \"type\": \"total\"}],
    \"filter\": {
      \"query\": \"service:${SERVICE} env:${ENV}\",
      \"from\": \"${FROM_ISO}\",
      \"to\": \"${TO_ISO}\"
    },
    \"group_by\": [{\"facet\": \"status\", \"total\": {\"type\": \"estimated_count\"}}]
  }" | jq -r '.data.buckets[]? | "\(.by.status): \(.computes.c0)"' 2>/dev/null \
  || echo "Could not aggregate logs"

echo ""
echo "=== P95 Latency (last ${MINUTES} min) ==="
curl -s "${BASE_URL}/api/v1/query?from=${FROM}&to=${TO}&query=p95:trace.web.request.duration%7Bservice:${SERVICE},env:${ENV}%7D" \
  "${AUTH_HEADERS[@]}" | \
  jq -r '.series[0].pointlist[-3:][] | "  \(.[0]/1000 | todate): \(.[1] | . * 100 | round / 100)ms"' 2>/dev/null \
  || echo "No APM data found"

echo ""
echo "Done. Check Datadog UI for full context: https://app.${DD_SITE}/apm/services/${SERVICE}"
