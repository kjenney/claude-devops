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

@test "handles missing context gracefully" {
  run bash "$SCRIPT" "Pod crash" ""
  # Script should handle missing context (either fail or use current)
  [ -n "$output" ]
}

@test "detects deployment issue type from problem description" {
  run bash "$SCRIPT" "Pod is in CrashLoopBackOff" "docker-desktop" "default" "my-app" 2>&1
  [[ "$output" == *"deployment"* ]] || [[ "$output" == *"Deployment"* ]]
}

@test "detects networking issue type from problem description" {
  run bash "$SCRIPT" "Service is not reachable" "docker-desktop" "default" "my-service" 2>&1
  [[ "$output" == *"networking"* ]] || [[ "$output" == *"Networking"* ]] || [[ "$output" == *"service"* ]]
}

@test "detects node issue type from problem description" {
  run bash "$SCRIPT" "Node is NotReady" "docker-desktop" "default" "node-1" 2>&1
  [[ "$output" == *"node"* ]] || [[ "$output" == *"Node"* ]]
}

@test "uses default namespace when not specified" {
  run bash "$SCRIPT" "Pod crash" "docker-desktop" 2>&1
  [[ "$output" == *"default"* ]] || [[ "$output" == *"Namespace"* ]]
}

@test "verifies kubectl access before investigation" {
  run bash "$SCRIPT" "Pod issue" "docker-desktop" "default" "my-pod" 2>&1
  [[ "$output" == *"Verifying kubectl"* ]] || [[ "$output" == *"verified"* ]]
}

@test "uses provided context" {
  run bash "$SCRIPT" "Pod crash" "docker-desktop" "default" "my-app" 2>&1
  [[ "$output" == *"docker-desktop"* ]]
}

@test "accepts optional resource name parameter" {
  run bash "$SCRIPT" "Deployment stuck" "docker-desktop" "production" "payment-service" 2>&1
  [[ "$output" == *"payment-service"* ]]
}
