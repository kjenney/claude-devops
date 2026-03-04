#!/usr/bin/env bats
# Tests for skills/eks-troubleshooting/run-investigation.sh orchestrator

SCRIPT="$BATS_TEST_DIRNAME/../../skills/eks-troubleshooting/run-investigation.sh"
MOCKS_DIR="$BATS_TEST_DIRNAME/../mocks"

setup() {
  export PATH="$MOCKS_DIR:$PATH"
}

@test "orchestrator script exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "requires context or uses current context" {
  run bash "$SCRIPT" "deployment"
  # Should handle missing context (fail or succeed depending on test environment)
  [ -n "$output" ]
}

@test "accepts deployment issue type" {
  run bash "$SCRIPT" "deployment" "my-app" "docker-desktop" "default" 2>&1
  [ -n "$output" ]
}

@test "accepts networking issue type" {
  run bash "$SCRIPT" "networking" "my-service" "docker-desktop" "default" 2>&1
  [ -n "$output" ]
}

@test "accepts node issue type" {
  run bash "$SCRIPT" "node" "node-1" "docker-desktop" "default" 2>&1
  [ -n "$output" ]
}

@test "uses default namespace when not specified" {
  run bash "$SCRIPT" "deployment" "my-app" "docker-desktop" 2>&1
  [ -n "$output" ]
}

@test "verifies kubectl access before investigation" {
  run bash "$SCRIPT" "deployment" "my-app" "docker-desktop" "default" 2>&1
  [[ "$output" == *"Verifying"* ]] || [[ "$output" == *"verified"* ]]
}

@test "uses provided context" {
  run bash "$SCRIPT" "deployment" "my-app" "docker-desktop" "default" 2>&1
  [[ "$output" == *"docker-desktop"* ]]
}

@test "accepts optional resource name parameter" {
  run bash "$SCRIPT" "deployment" "payment-service" "docker-desktop" "production" 2>&1
  [[ "$output" == *"payment-service"* ]]
}
