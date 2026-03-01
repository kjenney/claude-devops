#!/usr/bin/env bash
# Test runner for devops-plugin
# Runs shellcheck static analysis and bats unit tests
#
# Prerequisites:
#   shellcheck: brew install shellcheck  (or apt install shellcheck)
#   bats-core:  brew install bats-core   (or apt install bats)
#
# Usage:
#   bash tests/run-tests.sh              # Run all tests
#   bash tests/run-tests.sh --lint-only  # shellcheck only
#   bash tests/run-tests.sh --test-only  # bats only

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="$PLUGIN_ROOT/tests"
PASS=0
FAIL=0

# ─── Color output ─────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}  PASS${RESET} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}  FAIL${RESET} $1"; FAIL=$((FAIL + 1)); }
info() { echo -e "${BOLD}==> $1${RESET}"; }
warn() { echo -e "${YELLOW}WARN${RESET} $1"; }

# ─── Argument parsing ─────────────────────────────────────────────────────────
RUN_LINT=true
RUN_TESTS=true

for arg in "$@"; do
  case "$arg" in
    --lint-only)  RUN_TESTS=false ;;
    --test-only)  RUN_LINT=false  ;;
  esac
done

echo ""
echo -e "${BOLD}devops-plugin test suite${RESET}"
echo "Plugin root: $PLUGIN_ROOT"
echo ""

# ─── Phase 1: shellcheck ──────────────────────────────────────────────────────
if $RUN_LINT; then
  info "Phase 1: shellcheck static analysis"

  if ! command -v shellcheck &>/dev/null; then
    warn "shellcheck not found. Install with: brew install shellcheck"
    warn "Skipping lint phase."
  else
    SCRIPTS=(
      "$PLUGIN_ROOT/skills/aws-troubleshooting/examples/investigate-rds.sh"
      "$PLUGIN_ROOT/skills/aws-troubleshooting/examples/investigate-lambda.sh"
      "$PLUGIN_ROOT/skills/eks-troubleshooting/examples/investigate-deployment.sh"
      "$PLUGIN_ROOT/skills/eks-troubleshooting/examples/investigate-networking.sh"
      "$PLUGIN_ROOT/skills/datadog-troubleshooting/examples/investigate-service.sh"
    )

    for script in "${SCRIPTS[@]}"; do
      name="$(basename "$script")"
      if shellcheck -S warning "$script" 2>/dev/null; then
        ok "shellcheck: $name"
      else
        fail "shellcheck: $name"
        shellcheck -S warning "$script" || true
      fi
    done
  fi
  echo ""
fi

# ─── Phase 2: bats unit tests ─────────────────────────────────────────────────
if $RUN_TESTS; then
  info "Phase 2: bats unit tests"

  if ! command -v bats &>/dev/null; then
    warn "bats not found. Install with: brew install bats-core"
    warn "Skipping test phase."
  else
    TEST_FILES=(
      "$TESTS_DIR/aws/investigate-rds.bats"
      "$TESTS_DIR/aws/investigate-lambda.bats"
      "$TESTS_DIR/eks/investigate-deployment.bats"
      "$TESTS_DIR/eks/investigate-networking.bats"
      "$TESTS_DIR/datadog/investigate-service.bats"
    )

    for test_file in "${TEST_FILES[@]}"; do
      name="$(basename "$test_file" .bats)"
      if bats --no-tempdir-cleanup "$test_file" 2>/dev/null; then
        ok "bats: $name"
      else
        fail "bats: $name"
        # Re-run to show failure output
        bats "$test_file" || true
      fi
    done
  fi
  echo ""
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
TOTAL=$((PASS + FAIL))
echo -e "${BOLD}Results: ${GREEN}${PASS} passed${RESET}, ${RED}${FAIL} failed${RESET} (${TOTAL} total)"
echo ""

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
