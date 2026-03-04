#!/usr/bin/env bash
# Automated EKS/Kubernetes investigation script that detects issue type and runs appropriate examples
# Usage: bash run-investigation.sh "<problem-description>" "<context>" "<namespace>" "[resource-name]"

set -euo pipefail

PROBLEM="${1:-}"
CONTEXT="${2:-}"
NAMESPACE="${3:-default}"
RESOURCE_NAME="${4:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLES_DIR="$SCRIPT_DIR/examples"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ -z "$CONTEXT" ]]; then
  CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
  if [[ -z "$CONTEXT" ]]; then
    echo -e "${RED}Error: kubectl context must be set or CONTEXT must be provided${NC}"
    exit 1
  fi
fi

export CONTEXT="$CONTEXT"
export NS="$NAMESPACE"

# Verify kubectl access
echo -e "${YELLOW}Verifying kubectl access to context: $CONTEXT${NC}"
if ! kubectl config use-context "$CONTEXT" > /dev/null 2>&1; then
  echo -e "${RED}Error: Cannot switch to kubectl context '$CONTEXT'${NC}"
  exit 1
fi

if ! kubectl cluster-info > /dev/null 2>&1; then
  echo -e "${RED}Error: Cannot connect to cluster with context '$CONTEXT'${NC}"
  exit 1
fi
echo -e "${GREEN}✓ kubectl access verified${NC}\n"

# Detect issue type from problem description
detect_issue_type() {
  local problem="$1"
  problem_lower=$(echo "$problem" | tr '[:upper:]' '[:lower:]')

  if [[ "$problem_lower" =~ deployment|pod.*crash|crash.*loop|image.*pull|pending.*pod ]]; then
    echo "deployment"
  elif [[ "$problem_lower" =~ service|network|connect|endpoint|dns|latency ]]; then
    echo "networking"
  elif [[ "$problem_lower" =~ node|notready|resource|memory|cpu ]]; then
    echo "node"
  elif [[ "$problem_lower" =~ ingress|route|load.?balanc ]]; then
    echo "ingress"
  else
    echo "generic"
  fi
}

# Run issue-specific investigation
run_investigation() {
  local issue_type="$1"
  local resource_name="$2"

  case "$issue_type" in
    deployment)
      echo -e "${YELLOW}Detected deployment/pod issue${NC}"
      if [[ -z "$resource_name" ]]; then
        echo -e "${RED}Deployment name required. Please provide the deployment name.${NC}"
        return 1
      fi
      echo -e "${YELLOW}Running deployment investigation for: $resource_name${NC}\n"
      bash "$EXAMPLES_DIR/investigate-deployment.sh" "$resource_name"
      ;;
    networking)
      echo -e "${YELLOW}Detected networking/service issue${NC}"
      if [[ -z "$resource_name" ]]; then
        echo -e "${RED}Service name required. Please provide the service name.${NC}"
        return 1
      fi
      echo -e "${YELLOW}Running networking investigation for: $resource_name${NC}\n"
      bash "$EXAMPLES_DIR/investigate-networking.sh" "$resource_name"
      ;;
    *)
      echo -e "${YELLOW}Issue type: $issue_type (generic investigation)${NC}"
      echo -e "${YELLOW}See references/kubernetes-resources.md for detailed kubectl commands${NC}"
      return 1
      ;;
  esac
}

# Main execution
ISSUE_TYPE=$(detect_issue_type "$PROBLEM")
echo -e "${GREEN}Detected issue type: $ISSUE_TYPE${NC}"
echo "Problem: $PROBLEM"
echo "Context: $CONTEXT"
echo "Namespace: $NAMESPACE"
if [[ -n "$RESOURCE_NAME" ]]; then
  echo "Resource: $RESOURCE_NAME"
fi
echo ""

if run_investigation "$ISSUE_TYPE" "$RESOURCE_NAME"; then
  echo -e "\n${GREEN}✓ Investigation complete${NC}"
else
  echo -e "\n${YELLOW}⚠ Issue-specific investigation not available${NC}"
  echo "Please manually run investigation commands. Refer to:"
  echo "  - SKILL.md for workflow guidance"
  echo "  - references/kubernetes-resources.md for detailed kubectl commands"
fi
