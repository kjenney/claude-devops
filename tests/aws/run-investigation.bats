#!/usr/bin/env bats
# Tests for skills/aws-troubleshooting/run-investigation.sh orchestrator

SCRIPT="$BATS_TEST_DIRNAME/../../skills/aws-troubleshooting/run-investigation.sh"
MOCKS_DIR="$BATS_TEST_DIRNAME/../mocks"

setup() {
  export AWS_PROFILE=test
  export AWS_DEFAULT_REGION=us-east-1
  export PATH="$MOCKS_DIR:$PATH"
}

@test "orchestrator script exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "requires service type argument" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "requires profile and region arguments" {
  run bash "$SCRIPT" "lambda" "my-function"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Profile"* ]] || [[ "$output" == *"region"* ]]
}

@test "executes for Lambda service type" {
  run bash "$SCRIPT" "lambda" "my-function" "test" "us-east-1" 2>&1
  # Script should output something (success or AWS error is acceptable)
  [ -n "$output" ]
}

@test "executes for RDS service type" {
  run bash "$SCRIPT" "rds" "my-db" "test" "us-east-1" 2>&1
  [ -n "$output" ]
}

@test "executes for EC2 service type" {
  run bash "$SCRIPT" "ec2" "i-12345" "test" "us-east-1" 2>&1
  [ -n "$output" ]
}

@test "includes AWS verification step" {
  run bash "$SCRIPT" "lambda" "my-function" "test" "us-east-1" 2>&1
  # Should mention verifying AWS access
  [[ "$output" == *"Verifying"* ]] || [[ "$output" == *"verified"* ]]
}
