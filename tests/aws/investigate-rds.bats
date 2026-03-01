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

@test "outputs RDS Instance Status header" {
  run bash "$SCRIPT" prod-db
  [ "$status" -eq 0 ]
  [[ "$output" == *"RDS Instance Status"* ]]
}

@test "outputs Recent RDS Events header" {
  run bash "$SCRIPT" prod-db
  [ "$status" -eq 0 ]
  [[ "$output" == *"Recent RDS Events"* ]]
}

@test "outputs CloudWatch Connection Count header" {
  run bash "$SCRIPT" prod-db
  [ "$status" -eq 0 ]
  [[ "$output" == *"CloudWatch"* ]]
}

@test "outputs FreeStorageSpace header" {
  run bash "$SCRIPT" prod-db
  [ "$status" -eq 0 ]
  [[ "$output" == *"FreeStorageSpace"* ]]
}

@test "outputs CPUUtilization header" {
  run bash "$SCRIPT" prod-db
  [ "$status" -eq 0 ]
  [[ "$output" == *"CPUUtilization"* ]]
}

@test "accepts any DB instance identifier" {
  run bash "$SCRIPT" my-custom-db-instance-name
  [ "$status" -eq 0 ]
}
