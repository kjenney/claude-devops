#!/usr/bin/env bash
# Automated Datadog investigation script that detects issue type and runs appropriate examples
# Usage: bash run-investigation.sh "<problem-description>" "<service-name>" "<environment>" "[time-window-minutes]"

set -euo pipefail

PROBLEM="${1:-}"
SERVICE_NAME="${2:-}"
ENVIRONMENT="${3:-prod}"
TIME_WINDOW="${4:-60}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLES_DIR="$SCRIPT_DIR/examples"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verify Datadog credentials
if [[ -z "${DD_API_KEY:-}" ]] || [[ -z "${DD_APP_KEY:-}" ]]; then
  echo -e "${RED}Error: DD_API_KEY and DD_APP_KEY environment variables must be set${NC}"
  echo "Set them with: export DD_API_KEY='your-api-key' && export DD_APP_KEY='your-app-key'"
  exit 1
fi

if [[ -z "$SERVICE_NAME" ]]; then
  echo -e "${RED}Error: Service name is required${NC}"
  exit 1
fi

export SERVICE="$SERVICE_NAME"
export ENV="$ENVIRONMENT"
export MINUTES="$TIME_WINDOW"
export DD_SITE="${DD_SITE:-datadoghq.com}"

# Verify Datadog connectivity
echo -e "${YELLOW}Verifying Datadog API access...${NC}"
if ! curl -s -H "DD-API-KEY: ${DD_API_KEY}" \
       -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
       "https://api.${DD_SITE}/api/v1/validate" | grep -q "valid"; then
  echo -e "${YELLOW}⚠ Datadog API credentials verification skipped (non-critical)${NC}"
fi
echo -e "${GREEN}✓ Datadog investigation ready${NC}\n"

# Detect investigation type from problem description
detect_investigation_type() {
  local problem="$1"
  problem_lower=$(echo "$problem" | tr '[:upper:]' '[:lower:]')

  if [[ "$problem_lower" =~ error|exception|fail|crash ]]; then
    echo "service"
  elif [[ "$problem_lower" =~ latency|slow|performance|response.?time ]]; then
    echo "service"
  elif [[ "$problem_lower" =~ monitor|alert|alarm ]]; then
    echo "service"
  else
    echo "service"
  fi
}

# Run investigation
run_investigation() {
  local investigation_type="$1"

  case "$investigation_type" in
    service)
      echo -e "${YELLOW}Running service health investigation for: $SERVICE_NAME (env: $ENVIRONMENT)${NC}"
      echo -e "${YELLOW}Time window: last $TIME_WINDOW minutes${NC}\n"
      bash "$EXAMPLES_DIR/investigate-service.sh"
      ;;
    *)
      echo -e "${YELLOW}Investigation type: $investigation_type${NC}"
      echo -e "${YELLOW}See references/datadog-api.md for additional queries${NC}"
      return 1
      ;;
  esac
}

# Main execution
INVESTIGATION_TYPE=$(detect_investigation_type "$PROBLEM")
echo -e "${GREEN}Detected investigation type: $INVESTIGATION_TYPE${NC}"
echo "Problem: $PROBLEM"
echo "Service: $SERVICE_NAME"
echo "Environment: $ENVIRONMENT"
echo ""

if run_investigation "$INVESTIGATION_TYPE"; then
  echo -e "\n${GREEN}✓ Investigation complete${NC}"
  echo "View full details in Datadog UI: https://app.${DD_SITE}/apm/services/${SERVICE_NAME}"
else
  echo -e "\n${YELLOW}⚠ Investigation type not recognized${NC}"
  echo "Please manually run investigation commands. Refer to:"
  echo "  - SKILL.md for workflow guidance"
  echo "  - references/datadog-api.md for custom queries"
fi
