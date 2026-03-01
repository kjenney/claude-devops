# AWS Service-Specific Investigation Commands

## EC2 / Auto Scaling

```bash
# Check instance state and status checks
aws ec2 describe-instances --instance-ids <id> \
  --query 'Reservations[*].Instances[*].{State:State.Name,Status:StateReason.Message,Type:InstanceType,AZ:Placement.AvailabilityZone}'

aws ec2 describe-instance-status --instance-ids <id> \
  --query 'InstanceStatuses[*].{SystemStatus:SystemStatus.Status,InstanceStatus:InstanceStatus.Status}'

# Check Auto Scaling group activity
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <name> \
  --max-items 20 \
  --query 'Activities[*].{Status:StatusCode,Cause:Cause,Start:StartTime}'

# List instances in ASG
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <name> \
  --query 'AutoScalingGroups[*].{Min:MinSize,Max:MaxSize,Desired:DesiredCapacity,Instances:Instances[*].InstanceId}'

# Get EC2 console output (useful when instance won't start)
aws ec2 get-console-output --instance-id <id> --latest
```

## RDS / Aurora

```bash
# Check RDS instance status
aws rds describe-db-instances \
  --db-instance-identifier <id> \
  --query 'DBInstances[*].{Status:DBInstanceStatus,Endpoint:Endpoint.Address,Engine:Engine,Class:DBInstanceClass,MultiAZ:MultiAZ}'

# Check recent events (failures, reboots, failovers)
aws rds describe-events \
  --source-identifier <id> \
  --source-type db-instance \
  --duration 60 \
  --query 'Events[*].{Time:Date,Message:Message}'

# Check Aurora cluster status
aws rds describe-db-clusters \
  --db-cluster-identifier <id> \
  --query 'DBClusters[*].{Status:Status,Writer:DBClusterMembers[?IsClusterWriter].DBInstanceIdentifier,Endpoint:Endpoint}'

# Check parameter groups
aws rds describe-db-parameters \
  --db-parameter-group-name <name> \
  --query 'Parameters[?IsModifiable==`true`].{Name:ParameterName,Value:ParameterValue}'

# Check connection count via CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=<id> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Maximum \
  --query 'Datapoints[*].{Time:Timestamp,Connections:Maximum}' | sort
```

## Lambda

```bash
# Check function configuration and recent errors
aws lambda get-function --function-name <name> \
  --query 'Configuration.{State:State,Timeout:Timeout,Memory:MemorySize,Runtime:Runtime,Handler:Handler,Role:Role}'

# Check function concurrency
aws lambda get-function-concurrency --function-name <name>
aws lambda get-account-settings

# List recent function errors (last 1 hour)
aws logs filter-log-events \
  --log-group-name /aws/lambda/<name> \
  --start-time $(date -d '1 hour ago' +%s000) \
  --filter-pattern "?ERROR ?Exception ?Task timed out"

# Check throttle metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Throttles \
  --dimensions Name=FunctionName,Value=<name> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum

# Get latest function version/aliases
aws lambda list-versions-by-function --function-name <name>
aws lambda list-aliases --function-name <name>
```

## ECS / Fargate

```bash
# List services in cluster
aws ecs list-services --cluster <cluster> \
  --query 'serviceArns' | tr -d '"[],' | xargs -I{} aws ecs describe-services \
  --cluster <cluster> --services {} \
  --query 'services[*].{Name:serviceName,Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}'

# Check service events (failed deployments, etc.)
aws ecs describe-services --cluster <cluster> --services <service> \
  --query 'services[*].events[:10].{Time:createdAt,Message:message}'

# List stopped tasks with reason
aws ecs list-tasks --cluster <cluster> --desired-status STOPPED \
  --query 'taskArns' | xargs -I{} aws ecs describe-tasks \
  --cluster <cluster> --tasks {} \
  --query 'tasks[*].{StopCode:stopCode,Reason:stoppedReason,Container:containers[*].{Name:name,Exit:exitCode,Reason:reason}}'

# Check running task container logs
aws ecs list-tasks --cluster <cluster> --service-name <service> --desired-status RUNNING
aws logs get-log-events \
  --log-group-name /ecs/<task-def> \
  --log-stream-name ecs/<container>/<task-id>
```

## S3

```bash
# Check bucket existence and region
aws s3api get-bucket-location --bucket <bucket>

# Check bucket policy
aws s3api get-bucket-policy --bucket <bucket>

# Check bucket ACL
aws s3api get-bucket-acl --bucket <bucket>

# Check public access block settings
aws s3api get-public-access-block --bucket <bucket>

# List recent objects or check specific key
aws s3 ls s3://<bucket>/<prefix>/ --recursive --human-readable

# Check S3 access logs (if enabled)
aws s3api get-bucket-logging --bucket <bucket>
```

## VPC / Networking

```bash
# Check security group rules for a resource
aws ec2 describe-security-groups --group-ids <sg-id> \
  --query 'SecurityGroups[*].{Name:GroupName,Inbound:IpPermissions,Outbound:IpPermissionsEgress}'

# Check NACL for subnet
aws ec2 describe-network-acls \
  --filters Name=association.subnet-id,Values=<subnet-id> \
  --query 'NetworkAcls[*].Entries'

# Check route tables for subnet
aws ec2 describe-route-tables \
  --filters Name=association.subnet-id,Values=<subnet-id> \
  --query 'RouteTables[*].Routes'

# Check VPC flow logs
aws ec2 describe-flow-logs \
  --filter Name=resource-id,Values=<vpc-id>

# Check VPC endpoints
aws ec2 describe-vpc-endpoints \
  --filters Name=vpc-id,Values=<vpc-id>
```

## ALB / Load Balancer

```bash
# List load balancers
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].{Name:LoadBalancerName,DNS:DNSName,State:State.Code,Type:Type}'

# Check target group health
aws elbv2 describe-target-groups \
  --query 'TargetGroups[*].TargetGroupArn' \
  | xargs -I{} aws elbv2 describe-target-health --target-group-arn {} \
  --query 'TargetHealthDescriptions[*].{Target:Target.Id,State:TargetHealth.State,Reason:TargetHealth.Reason}'

# Check listener rules
aws elbv2 describe-listeners --load-balancer-arn <arn>
aws elbv2 describe-rules --listener-arn <arn>

# Check ALB access logs (S3)
aws elbv2 describe-load-balancer-attributes \
  --load-balancer-arn <arn> \
  --query 'Attributes[?Key==`access_logs.s3.enabled`]'
```

## DynamoDB

```bash
# Check table status and throughput
aws dynamodb describe-table --table-name <name> \
  --query 'Table.{Status:TableStatus,ProvisionedThroughput:ProvisionedThroughput,BillingMode:BillingModeSummary.BillingMode,ItemCount:ItemCount}'

# Check consumed capacity via CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedWriteCapacityUnits \
  --dimensions Name=TableName,Value=<name> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Sum

# Check throttling
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name WriteThrottleEvents \
  --dimensions Name=TableName,Value=<name> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Sum
```

## CloudWatch Alarms & Metrics

```bash
# List alarms in ALARM state
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'MetricAlarms[*].{Name:AlarmName,Metric:MetricName,Namespace:Namespace,Reason:StateReason,Updated:StateUpdatedTimestamp}'

# Get alarm history
aws cloudwatch describe-alarm-history \
  --alarm-name <name> \
  --history-item-type StateUpdate \
  --max-records 10

# Get metric data for a time range
aws cloudwatch get-metric-data \
  --metric-data-queries '[{"Id":"m1","MetricStat":{"Metric":{"Namespace":"AWS/EC2","MetricName":"CPUUtilization","Dimensions":[{"Name":"InstanceId","Value":"<id>"}]},"Period":300,"Stat":"Average"}}]' \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ)

# Search logs across multiple streams
aws logs start-query \
  --log-group-name <group> \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 50'

# Get insights query results
aws logs get-query-results --query-id <id>
```
