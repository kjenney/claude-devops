#!/usr/bin/env bats
# Tests for skills/eks-troubleshooting/examples/investigate-networking.sh

SCRIPT="$BATS_TEST_DIRNAME/../../skills/eks-troubleshooting/examples/investigate-networking.sh"
MOCKS_DIR="$BATS_TEST_DIRNAME/../mocks"

setup() {
  export CONTEXT=prod-cluster
  export NS=production
  export PATH="$MOCKS_DIR:$PATH"
}

@test "script exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -r "$SCRIPT" ]
}

@test "requires SERVICE argument" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "outputs context and namespace header" {
  run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"prod-cluster"* ]]
  [[ "$output" == *"production"* ]]
}

@test "outputs Service Details header" {
  run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"Service Details"* ]]
}

@test "outputs Endpoint Health header" {
  run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"Endpoint Health"* ]]
}

@test "outputs DNS Resolution Test header" {
  run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"DNS"* ]]
}

@test "outputs Network Policies header" {
  run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"Network Policies"* ]]
}

@test "outputs Recent Warning Events header" {
  run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"Events"* ]]
}

@test "uses NS env var for namespace" {
  NS=staging run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"staging"* ]]
}
