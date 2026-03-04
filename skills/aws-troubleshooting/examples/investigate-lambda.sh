#!/usr/bin/env bash
# Example: Investigate Lambda function errors
#
# AUTOMATED: This script is automatically called by run-investigation.sh when Lambda issues are detected.
# It can also be run directly for manual investigation.
#
# Usage: AWS_PROFILE=prod AWS_DEFAULT_REGION=us-east-1 bash investigate-lambda.sh my-function-name [time-window-minutes]
# Example: AWS_PROFILE=prod AWS_DEFAULT_REGION=us-east-1 bash investigate-lambda.sh payment-processor 30

set -euo pipefail

FUNCTION_NAME="${1:?Usage: $0 <function-name>}"
MINUTES="${2:-30}"

START_TIME_MS=$(( $(date +%s) * 1000 - MINUTES * 60 * 1000 ))

echo "=== Lambda Configuration ==="
aws lambda get-function --function-name "$FUNCTION_NAME" \
  --query 'Configuration.{State:State,Runtime:Runtime,Handler:Handler,Timeout:Timeout,MemorySize:MemorySize,LastModified:LastModified,Role:Role}' \
  --output table

echo ""
echo "=== Lambda Concurrency ==="
aws lambda get-function-concurrency --function-name "$FUNCTION_NAME" 2>/dev/null \
  || echo "No reserved concurrency set (uses account-level limit)"

echo ""
echo "=== Recent Errors & Timeouts (last ${MINUTES} min) ==="
aws logs filter-log-events \
  --log-group-name "/aws/lambda/$FUNCTION_NAME" \
  --start-time "$START_TIME_MS" \
  --filter-pattern "?ERROR ?Exception ?\"Task timed out\"" \
  --query 'events[*].{Time:timestamp,Message:message}' \
  --output table 2>/dev/null || echo "No log group found or no matching events"

echo ""
echo "=== CloudWatch: Invocations & Errors (last ${MINUTES} min) ==="
START_TIME=$(date -u -d "${MINUTES} minutes ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-${MINUTES}M +%Y-%m-%dT%H:%M:%SZ)
END_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)

for metric in Invocations Errors Throttles Duration; do
  echo "--- $metric ---"
  aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name "$metric" \
    --dimensions Name=FunctionName,Value="$FUNCTION_NAME" \
    --start-time "$START_TIME" \
    --end-time "$END_TIME" \
    --period 300 \
    --statistics Sum Average \
    --query 'Datapoints[*].{Sum:Sum,Average:Average}' \
    --output table
done
