#!/usr/bin/env bats
# Tests for skills/aws-troubleshooting/examples/investigate-lambda.sh

SCRIPT="$BATS_TEST_DIRNAME/../../skills/aws-troubleshooting/examples/investigate-lambda.sh"
MOCKS_DIR="$BATS_TEST_DIRNAME/../mocks"

setup() {
  export AWS_PROFILE=test
  export AWS_DEFAULT_REGION=us-east-1
  export PATH="$MOCKS_DIR:$PATH"
}

@test "script exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -r "$SCRIPT" ]
}

@test "requires FUNCTION_NAME argument" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "outputs Lambda Configuration header" {
  run bash "$SCRIPT" payment-processor
  [ "$status" -eq 0 ]
  [[ "$output" == *"Lambda Configuration"* ]]
}

@test "outputs Lambda Concurrency header" {
  run bash "$SCRIPT" payment-processor
  [ "$status" -eq 0 ]
  [[ "$output" == *"Lambda Concurrency"* ]]
}

@test "outputs Recent Errors and Timeouts header" {
  run bash "$SCRIPT" payment-processor
  [ "$status" -eq 0 ]
  [[ "$output" == *"Errors"* ]]
}

@test "outputs CloudWatch metrics section" {
  run bash "$SCRIPT" payment-processor
  [ "$status" -eq 0 ]
  [[ "$output" == *"CloudWatch"* ]]
}

@test "accepts custom time window in minutes" {
  run bash "$SCRIPT" payment-processor 15
  [ "$status" -eq 0 ]
  [[ "$output" == *"15 min"* ]]
}

@test "defaults to 30 minute window" {
  run bash "$SCRIPT" payment-processor
  [ "$status" -eq 0 ]
  [[ "$output" == *"30 min"* ]]
}
