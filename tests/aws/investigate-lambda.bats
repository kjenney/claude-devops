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

@test "script runs with function name" {
  run bash "$SCRIPT" payment-processor
  # Script should produce output
  [ -n "$output" ]
}

@test "script accepts custom time window parameter" {
  run bash "$SCRIPT" payment-processor 15
  # Script should run with time window parameter
  [ -n "$output" ]
}

@test "script defaults to 30 minute window" {
  run bash "$SCRIPT" payment-processor
  # Script should use default time window and produce output
  [ -n "$output" ]
}

@test "script accepts any function name" {
  run bash "$SCRIPT" my-custom-function
  # Script should run with any function name
  [ -n "$output" ]
}
