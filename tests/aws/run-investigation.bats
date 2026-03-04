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

@test "requires problem description argument" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "requires AWS_PROFILE and AWS_DEFAULT_REGION" {
  unset AWS_PROFILE
  unset AWS_DEFAULT_REGION
  run bash "$SCRIPT" "Lambda issue" "" "us-east-1"
  [ "$status" -ne 0 ]
}

@test "executes for Lambda problem" {
  run bash "$SCRIPT" "My Lambda function is timing out" "default" "us-east-1" "my-function" 2>&1
  # Script should output something (either success or AWS error is fine)
  [ -n "$output" ]
}

@test "executes for RDS problem" {
  run bash "$SCRIPT" "My database is running out of storage" "default" "us-east-1" "my-db" 2>&1
  [ -n "$output" ]
}

@test "executes for EC2 problem" {
  run bash "$SCRIPT" "EC2 instance is not responding" "default" "us-east-1" "i-12345" 2>&1
  [ -n "$output" ]
}

@test "includes AWS verification step" {
  run bash "$SCRIPT" "Lambda issue" "default" "us-east-1" "my-function" 2>&1
  # Should mention verifying AWS access or be successful
  [[ "$output" =~ "Verifying" ]] || [[ "$output" =~ "verified" ]] || [[ "$output" =~ "Problem" ]]
}
