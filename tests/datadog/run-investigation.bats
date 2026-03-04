#!/usr/bin/env bats
# Tests for skills/datadog-troubleshooting/run-investigation.sh orchestrator

SCRIPT="$BATS_TEST_DIRNAME/../../skills/datadog-troubleshooting/run-investigation.sh"

setup() {
  export DD_API_KEY="test-api-key"
  export DD_APP_KEY="test-app-key"
  export DD_SITE="datadoghq.com"
}

@test "orchestrator script exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "requires problem description argument" {
  run bash "$SCRIPT"
  [ "$status" -ne 0 ]
}

@test "requires DD_API_KEY environment variable" {
  unset DD_API_KEY
  run bash "$SCRIPT" "Service error" "payment-api" "prod"
  [ "$status" -ne 0 ]
  [[ "$output" == *"DD_API_KEY"* ]]
}

@test "requires DD_APP_KEY environment variable" {
  unset DD_APP_KEY
  run bash "$SCRIPT" "Service error" "payment-api" "prod"
  [ "$status" -ne 0 ]
  [[ "$output" == *"DD_APP_KEY"* ]]
}

@test "requires service name argument" {
  run bash "$SCRIPT" "Service error" "" "prod"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Service name"* ]]
}

@test "detects service investigation type" {
  run bash "$SCRIPT" "Payment API errors spiking" "payment-api" "prod" 2>&1
  [[ "$output" == *"service"* ]] || [[ "$output" == *"Service"* ]]
}

@test "uses default environment when not specified" {
  run bash "$SCRIPT" "Service error" "payment-api" 2>&1
  [[ "$output" == *"prod"* ]] || [[ "$output" == *"Environment"* ]]
}

@test "uses default time window when not specified" {
  run bash "$SCRIPT" "Service error" "payment-api" "prod" 2>&1
  [[ "$output" == *"60"* ]] || [[ "$output" == *"time window"* ]]
}

@test "accepts custom time window in minutes" {
  run bash "$SCRIPT" "Service error" "payment-api" "prod" "120" 2>&1
  [[ "$output" == *"120"* ]]
}

@test "accepts custom Datadog site" {
  DD_SITE="datadoghq.eu" run bash "$SCRIPT" "Service error" "payment-api" "prod" 2>&1
  [[ "$output" == *"datadoghq.eu"* ]] || [[ "$output" == *"app.datadoghq.eu"* ]]
}

@test "sets SERVICE environment variable for example script" {
  run bash "$SCRIPT" "Service error" "payment-api" "prod" 2>&1
  # The script should pass SERVICE to the example
  [[ "$output" == *"payment-api"* ]]
}
