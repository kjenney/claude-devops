#!/usr/bin/env bash
# Security check for sensitive operations
# Usage: bash security-check.sh "<command-line>"

set -euo pipefail

COMMAND="${1:-}"
AUDIT_LOG="${HOME}/.claude/audit.log"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Check for sensitive AWS operations
check_aws_sensitive() {
  local cmd="$1"
  if [[ "$cmd" =~ aws\ (iam|ec2|rds|lambda).*delete|aws\ iam.*attach|aws\ iam.*put-user-policy|aws\ ec2.*terminate-instances|aws\ rds.*delete-db ]]; then
    echo -e "${RED}🚨 SENSITIVE AWS OPERATION DETECTED${NC}"
    echo "Command: $cmd"
    echo "This operation modifies or deletes resources. Ensure this is intentional."

    # Log to audit
    bash "$(dirname "${BASH_SOURCE[0]}")/audit-log.sh" "sensitive_operation" "AWS: $cmd"

    return 1  # Failure to trigger visibility
  fi
}

# Check for sensitive K8s operations
check_k8s_sensitive() {
  local cmd="$1"
  if [[ "$cmd" =~ kubectl.*delete.*pod|kubectl.*delete.*deployment|kubectl.*create.*secret|kubectl.*patch.*RBAC ]]; then
    echo -e "${RED}🚨 SENSITIVE KUBERNETES OPERATION DETECTED${NC}"
    echo "Command: $cmd"
    echo "This operation modifies or deletes K8s resources. Ensure this is intentional."

    # Log to audit
    bash "$(dirname "${BASH_SOURCE[0]}")/audit-log.sh" "sensitive_operation" "K8s: $cmd"

    return 1  # Failure to trigger visibility
  fi
}

# Check for production environment access
check_production_access() {
  local cmd="$1"
  local profile="${AWS_PROFILE:-${CONTEXT:-}}"

  if [[ "$profile" =~ prod|production|prd ]]; then
    echo -e "${YELLOW}🔒 PRODUCTION ENVIRONMENT ACCESS${NC}"
    echo "Profile/Context: $profile"
    echo "Command: $cmd"

    # Log to audit
    bash "$(dirname "${BASH_SOURCE[0]}")/audit-log.sh" "production_access" "$profile: $cmd"
  fi
}

# Run checks
check_aws_sensitive "$COMMAND"
check_k8s_sensitive "$COMMAND"
check_production_access "$COMMAND"

exit 0
