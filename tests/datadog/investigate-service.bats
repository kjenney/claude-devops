#!/usr/bin/env bats
# Tests for skills/datadog-troubleshooting/examples/investigate-service.sh

SCRIPT="$BATS_TEST_DIRNAME/../../skills/datadog-troubleshooting/examples/investigate-service.sh"
MOCKS_DIR="$BATS_TEST_DIRNAME/../mocks"

setup() {
  export SERVICE=payment-api
  export ENV=prod
  export DD_API_KEY=test-api-key-12345
  export DD_APP_KEY=test-app-key-67890
  export DD_SITE=datadoghq.com
  export MINUTES=60
  export PATH="$MOCKS_DIR:$PATH"
}

@test "script exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -r "$SCRIPT" ]
}

@test "requires SERVICE env var" {
  run env -u SERVICE bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"SERVICE"* ]]
}

@test "requires DD_API_KEY env var" {
  run env -u DD_API_KEY bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"DD_API_KEY"* ]]
}

@test "requires DD_APP_KEY env var" {
  run env -u DD_APP_KEY bash "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"DD_APP_KEY"* ]]
}

@test "outputs service and environment in header" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"payment-api"* ]]
  [[ "$output" == *"prod"* ]]
}

@test "outputs Triggered Monitors section" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Monitors"* ]]
}

@test "outputs Recent Error Logs section" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Error Logs"* ]]
}

@test "outputs Error Count by Status section" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Error Count"* ]]
}

@test "outputs P95 Latency section" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"P95 Latency"* ]]
}

@test "outputs Datadog app URL at the end" {
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"datadoghq.com"* ]]
  [[ "$output" == *"payment-api"* ]]
}

@test "uses MINUTES env var for time window" {
  MINUTES=15 run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"15 min"* ]]
}

@test "uses custom DD_SITE for EU customers" {
  DD_SITE=datadoghq.eu run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"datadoghq.eu"* ]]
}
