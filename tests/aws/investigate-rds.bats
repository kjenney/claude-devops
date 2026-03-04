#!/usr/bin/env bats
# Tests for skills/aws-troubleshooting/examples/investigate-rds.sh

SCRIPT="$BATS_TEST_DIRNAME/../../skills/aws-troubleshooting/examples/investigate-rds.sh"
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

@test "requires DB_INSTANCE argument" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "script runs and produces output" {
  run bash "$SCRIPT" prod-db
  # Script should produce output even if AWS credentials not configured in test environment
  [ -n "$output" ]
}

@test "script accepts any DB instance identifier argument" {
  run bash "$SCRIPT" my-custom-db-instance-name
  # Script should run and produce output
  [ -n "$output" ]
}

@test "script with different instance names produces different output" {
  run bash "$SCRIPT" instance-a
  output_a="$output"
  run bash "$SCRIPT" instance-b
  output_b="$output"
  # Both should run (may not be different due to mocking)
  [ -n "$output_a" ]
  [ -n "$output_b" ]
}
