#!/usr/bin/env bash
# Automated EKS/Kubernetes investigation script that runs investigation for a specific issue type
# Usage: bash run-investigation.sh "<issue-type>" "<resource-name>" "<context>" "<namespace>"
# issue-type: deployment, networking, node, ingress

set -euo pipefail

ISSUE_TYPE="${1:-}"
RESOURCE_NAME="${2:-}"
CONTEXT="${3:-}"
NAMESPACE="${4:-default}"
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

if [[ -z "$ISSUE_TYPE" ]]; then
  echo -e "${RED}Error: Issue type required (deployment, networking, node, ingress)${NC}"
  exit 1
fi

# Run issue-specific investigation
case "$ISSUE_TYPE" in
  deployment)
    echo -e "${YELLOW}Investigating deployment: $RESOURCE_NAME${NC}\n"
    if [[ -z "$RESOURCE_NAME" ]]; then
      echo -e "${RED}Error: Deployment name required${NC}"
      exit 1
    fi
    bash "$EXAMPLES_DIR/investigate-deployment.sh" "$RESOURCE_NAME"
    ;;
  networking)
    echo -e "${YELLOW}Investigating service: $RESOURCE_NAME${NC}\n"
    if [[ -z "$RESOURCE_NAME" ]]; then
      echo -e "${RED}Error: Service name required${NC}"
      exit 1
    fi
    bash "$EXAMPLES_DIR/investigate-networking.sh" "$RESOURCE_NAME"
    ;;
  node|ingress)
    echo -e "${YELLOW}Issue type: $ISSUE_TYPE${NC}"
    echo -e "${YELLOW}Refer to SKILL.md and references/kubernetes-resources.md for $ISSUE_TYPE investigation commands${NC}"
    exit 1
    ;;
  *)
    echo -e "${RED}Error: Unknown issue type '$ISSUE_TYPE'${NC}"
    echo "Supported types: deployment, networking, node, ingress"
    exit 1
    ;;
esac
