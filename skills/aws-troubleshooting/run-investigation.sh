#!/usr/bin/env bash
# Automated AWS investigation script that detects service type and runs appropriate examples
# Usage: bash run-investigation.sh "<problem-description>" "<profile>" "<region>" "[function-or-resource-name]"

set -euo pipefail

PROBLEM="${1:-}"
PROFILE="${2:-}"
REGION="${3:-}"
RESOURCE_NAME="${4:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLES_DIR="$SCRIPT_DIR/examples"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ -z "$PROFILE" ]] || [[ -z "$REGION" ]]; then
  echo -e "${RED}Error: AWS_PROFILE and AWS_DEFAULT_REGION must be set${NC}"
  exit 1
fi

export AWS_PROFILE="$PROFILE"
export AWS_DEFAULT_REGION="$REGION"

# Verify AWS access
echo -e "${YELLOW}Verifying AWS access...${NC}"
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo -e "${RED}Error: Cannot authenticate with AWS profile '$PROFILE' in region '$REGION'${NC}"
  exit 1
fi
echo -e "${GREEN}✓ AWS access verified${NC}\n"

# Detect service type from problem description
detect_service_type() {
  local problem="$1"
  problem_lower=$(echo "$problem" | tr '[:upper:]' '[:lower:]')

  if [[ "$problem_lower" =~ lambda|function ]]; then
    echo "lambda"
  elif [[ "$problem_lower" =~ rds|database|postgres|mysql|aurora ]]; then
    echo "rds"
  elif [[ "$problem_lower" =~ ec2|instance|ami ]]; then
    echo "ec2"
  elif [[ "$problem_lower" =~ ecs|fargate|task|container ]]; then
    echo "ecs"
  elif [[ "$problem_lower" =~ s3|bucket ]]; then
    echo "s3"
  elif [[ "$problem_lower" =~ alb|load.?balancer|target.?group ]]; then
    echo "alb"
  elif [[ "$problem_lower" =~ vpc|security.?group|network|nacl ]]; then
    echo "vpc"
  else
    echo "generic"
  fi
}

# Run service-specific investigation
run_investigation() {
  local service_type="$1"
  local resource_name="$2"

  case "$service_type" in
    lambda)
      echo -e "${YELLOW}Detected Lambda function issue${NC}"
      if [[ -z "$resource_name" ]]; then
        echo -e "${RED}Lambda function name required. Please provide the function name.${NC}"
        return 1
      fi
      echo -e "${YELLOW}Running Lambda investigation for: $resource_name${NC}\n"
      bash "$EXAMPLES_DIR/investigate-lambda.sh" "$resource_name" 30
      ;;
    rds)
      echo -e "${YELLOW}Detected RDS database issue${NC}"
      if [[ -z "$resource_name" ]]; then
        echo -e "${RED}RDS instance ID required. Please provide the DB instance identifier.${NC}"
        return 1
      fi
      echo -e "${YELLOW}Running RDS investigation for: $resource_name${NC}\n"
      bash "$EXAMPLES_DIR/investigate-rds.sh" "$resource_name"
      ;;
    *)
      echo -e "${YELLOW}Service type: $service_type (generic investigation)${NC}"
      echo -e "${YELLOW}See references/aws-services.md for service-specific commands${NC}"
      return 1
      ;;
  esac
}

# Main execution
SERVICE_TYPE=$(detect_service_type "$PROBLEM")
echo -e "${GREEN}Detected service type: $SERVICE_TYPE${NC}"
echo "Problem: $PROBLEM"
if [[ -n "$RESOURCE_NAME" ]]; then
  echo "Resource: $RESOURCE_NAME"
fi
echo ""

if run_investigation "$SERVICE_TYPE" "$RESOURCE_NAME"; then
  echo -e "\n${GREEN}✓ Investigation complete${NC}"
else
  echo -e "\n${YELLOW}⚠ Service-specific investigation not available${NC}"
  echo "Please manually run investigation commands. Refer to:"
  echo "  - SKILL.md for workflow guidance"
  echo "  - references/aws-services.md for service-specific CLI commands"
fi
