#!/usr/bin/env bats
# Tests for skills/eks-troubleshooting/examples/investigate-deployment.sh

SCRIPT="$BATS_TEST_DIRNAME/../../skills/eks-troubleshooting/examples/investigate-deployment.sh"
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

@test "requires DEPLOYMENT argument" {
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

@test "outputs Deployment Status header" {
  run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"Deployment Status"* ]]
}

@test "outputs Rollout Status header" {
  run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"Rollout Status"* ]]
}

@test "outputs Deployment Events header" {
  run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"Deployment Events"* ]]
}

@test "outputs Pods header" {
  run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pods"* ]]
}

@test "outputs Pod Restart Counts header" {
  run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"Restart"* ]]
}

@test "outputs Recent Namespace Events header" {
  run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"Events"* ]]
}

@test "uses NS env var for namespace" {
  NS=staging run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"staging"* ]]
}

@test "uses CONTEXT env var for kubectl context" {
  CONTEXT=staging-cluster run bash "$SCRIPT" my-service
  [ "$status" -eq 0 ]
  [[ "$output" == *"staging-cluster"* ]]
}
