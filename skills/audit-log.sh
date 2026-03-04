#!/usr/bin/env bash
# Audit logging script for security and compliance tracking
# Usage: bash audit-log.sh "<event-type>" "<details>"

set -euo pipefail

EVENT_TYPE="${1:-unknown}"
DETAILS="${2:-}"
AUDIT_LOG="${HOME}/.claude/audit.log"
AUDIT_DIR="$(dirname "$AUDIT_LOG")"

# Ensure audit directory exists
mkdir -p "$AUDIT_DIR"

# Get current user
CURRENT_USER="${USER:-unknown}"

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get environment (prod/staging/dev from context or profile)
ENVIRONMENT="${AWS_DEFAULT_REGION:-${CONTEXT:-unknown}}"
if [[ "$ENVIRONMENT" == "prod"* ]] || [[ "$ENVIRONMENT" =~ ^eu-|^us-|^ap- ]]; then
  ENV_TYPE="prod"
elif [[ "$ENVIRONMENT" == "stag"* ]]; then
  ENV_TYPE="staging"
else
  ENV_TYPE="dev"
fi

# Build audit entry
AUDIT_ENTRY=$(cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "user": "$CURRENT_USER",
  "event_type": "$EVENT_TYPE",
  "environment": "$ENV_TYPE",
  "details": "$DETAILS"
}
EOF
)

# Write to audit log
echo "$AUDIT_ENTRY" >> "$AUDIT_LOG"

# Also echo for visibility
case "$EVENT_TYPE" in
  investigation_request)
    echo "📋 [AUDIT] Investigation initiated: $DETAILS"
    ;;
  sensitive_operation)
    echo "⚠️  [SECURITY] Sensitive operation detected: $DETAILS"
    ;;
  production_access)
    echo "🔒 [PROD ACCESS] Production resource accessed: $DETAILS"
    ;;
  *)
    echo "📝 [LOG] $EVENT_TYPE: $DETAILS"
    ;;
esac
