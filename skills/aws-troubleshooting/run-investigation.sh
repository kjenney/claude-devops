#!/usr/bin/env bash
# Automated AWS investigation script that runs investigation for a specific service type
# Usage: bash run-investigation.sh "<service-type>" "<resource-name>" "<profile>" "<region>"
# service-type: lambda, rds, ec2, ecs, s3, alb, vpc

set -euo pipefail

SERVICE_TYPE="${1:-}"
RESOURCE_NAME="${2:-}"
PROFILE="${3:-}"
REGION="${4:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLES_DIR="$SCRIPT_DIR/examples"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ -z "$SERVICE_TYPE" ]]; then
  echo -e "${RED}Error: Service type required (lambda, rds, ec2, ecs, s3, alb, vpc)${NC}"
  exit 1
fi

if [[ -z "$PROFILE" ]] || [[ -z "$REGION" ]]; then
  echo -e "${RED}Error: Profile and region required${NC}"
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

# Run service-specific investigation
case "$SERVICE_TYPE" in
  lambda)
    echo -e "${YELLOW}Investigating Lambda function: $RESOURCE_NAME${NC}\n"
    if [[ -z "$RESOURCE_NAME" ]]; then
      echo -e "${RED}Error: Lambda function name required${NC}"
      exit 1
    fi
    bash "$EXAMPLES_DIR/investigate-lambda.sh" "$RESOURCE_NAME" 30 "$REGION"
    ;;
  rds)
    echo -e "${YELLOW}Investigating RDS instance: $RESOURCE_NAME${NC}\n"
    if [[ -z "$RESOURCE_NAME" ]]; then
      echo -e "${RED}Error: RDS instance ID required${NC}"
      exit 1
    fi
    bash "$EXAMPLES_DIR/investigate-rds.sh" "$RESOURCE_NAME" 60 "$REGION"
    ;;
  ec2|ecs|s3|alb|vpc)
    echo -e "${YELLOW}Service type: $SERVICE_TYPE${NC}"
    echo -e "${YELLOW}Refer to SKILL.md and references/aws-services.md for $SERVICE_TYPE investigation commands${NC}"
    exit 1
    ;;
  *)
    echo -e "${RED}Error: Unknown service type '$SERVICE_TYPE'${NC}"
    echo "Supported types: lambda, rds, ec2, ecs, s3, alb, vpc"
    exit 1
    ;;
esac
