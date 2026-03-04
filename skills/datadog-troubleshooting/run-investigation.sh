#!/usr/bin/env bash
# Automated Datadog investigation script that queries service health
# Usage: bash run-investigation.sh "<service-name>" "<environment>" "[time-window-minutes]"

set -euo pipefail

SERVICE_NAME="${1:-}"
ENVIRONMENT="${2:-prod}"
TIME_WINDOW="${3:-60}"
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

# Run service health investigation
echo -e "${YELLOW}Running service health investigation for: $SERVICE_NAME (env: $ENVIRONMENT)${NC}"
echo -e "${YELLOW}Time window: last $TIME_WINDOW minutes${NC}\n"
bash "$EXAMPLES_DIR/investigate-service.sh"

echo -e "\n${GREEN}✓ Investigation complete${NC}"
echo "View full details in Datadog UI: https://app.${DD_SITE}/apm/services/${SERVICE_NAME}"
