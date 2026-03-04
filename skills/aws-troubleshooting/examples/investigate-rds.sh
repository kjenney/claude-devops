#!/usr/bin/env bash
# Example: Investigate RDS connection issues
#
# AUTOMATED: This script is automatically called by run-investigation.sh when RDS/database issues are detected.
# It can also be run directly for manual investigation.
#
# Usage: AWS_PROFILE=prod AWS_DEFAULT_REGION=us-east-1 bash investigate-rds.sh <db-instance-id> [time-window-minutes]
# Example: AWS_PROFILE=prod AWS_DEFAULT_REGION=us-east-1 bash investigate-rds.sh prod-db-instance 60

set -euo pipefail

DB_INSTANCE="${1:?Usage: $0 <db-instance-id>}"

echo "=== RDS Instance Status ==="
aws rds describe-db-instances \
  --db-instance-identifier "$DB_INSTANCE" \
  --query 'DBInstances[*].{Status:DBInstanceStatus,Endpoint:Endpoint.Address,Port:Endpoint.Port,Engine:Engine,Class:DBInstanceClass,MultiAZ:MultiAZ,StorageType:StorageType,AllocatedStorage:AllocatedStorage}' \
  --output table

echo ""
echo "=== Recent RDS Events (last 60 min) ==="
aws rds describe-events \
  --source-identifier "$DB_INSTANCE" \
  --source-type db-instance \
  --duration 60 \
  --query 'Events[*].{Time:Date,Message:Message}' \
  --output table

echo ""
echo "=== CloudWatch: Connection Count (last 1 hour) ==="
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value="$DB_INSTANCE" \
  --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-1H +%Y-%m-%dT%H:%M:%SZ)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --period 300 \
  --statistics Maximum \
  --query 'sort_by(Datapoints, &Timestamp)[*].{Time:Timestamp,MaxConnections:Maximum}' \
  --output table

echo ""
echo "=== CloudWatch: FreeStorageSpace (last 1 hour) ==="
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name FreeStorageSpace \
  --dimensions Name=DBInstanceIdentifier,Value="$DB_INSTANCE" \
  --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-1H +%Y-%m-%dT%H:%M:%SZ)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --period 300 \
  --statistics Minimum \
  --query 'sort_by(Datapoints, &Timestamp)[-1].{LastMinFreeStorageBytes:Minimum}' \
  --output table

echo ""
echo "=== CloudWatch: CPUUtilization (last 1 hour) ==="
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value="$DB_INSTANCE" \
  --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-1H +%Y-%m-%dT%H:%M:%SZ)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --period 300 \
  --statistics Average \
  --query 'sort_by(Datapoints, &Timestamp)[*].{Time:Timestamp,CPU:Average}' \
  --output table
