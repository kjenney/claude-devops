---
name: AWS Troubleshooting
description: This skill should be used when the user asks to "troubleshoot AWS", "investigate AWS resources", "debug EC2 instance", "check RDS connections", "diagnose Lambda errors", "investigate ECS task failures", "debug S3 access", "check CloudWatch alarms", "investigate IAM permissions", "debug VPC networking", "check ALB health", or mentions AWS resource errors, failures, or anomalies. Provides systematic AWS investigation workflows using the AWS CLI.
---

# AWS Troubleshooting

A structured approach to diagnosing and resolving AWS resource issues using the AWS CLI with named profiles. Covers compute (EC2, Lambda, ECS/Fargate), data (RDS, S3, DynamoDB), networking (VPC, ALB, CloudFront), and observability (CloudWatch, alarms).

## Prerequisites

Ensure the following are available before starting:
- AWS CLI installed and configured (`aws --version`)
- Named profiles in `~/.aws/config` for each environment
- Appropriate IAM permissions for the resources being investigated

## Core Workflow

### 1. Gather Context

Before running any commands, collect:
- **What is broken**: Error message, symptom, alert description
- **When it started**: Approximate time window for log queries
- **Which environment**: AWS account and region (derive from profile)
- **Which resource**: Service type and resource identifier

Ask the user: "Which AWS profile and region should I use?" then set:

```bash
export AWS_PROFILE=<profile>
export AWS_DEFAULT_REGION=<region>
```

### 2. Verify AWS Access

```bash
aws sts get-caller-identity
aws configure list --profile $AWS_PROFILE
```

### 3. Investigate by Service

Use the service-specific workflows in `references/aws-services.md` based on the resource type involved.

### 4. Check CloudWatch for Signals

Always check CloudWatch logs and metrics as a cross-cutting concern:

```bash
# List recent log groups matching a service name
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/<name>"

# Get recent log events (last 30 minutes)
aws logs filter-log-events \
  --log-group-name "<log-group>" \
  --start-time $(date -d '30 minutes ago' +%s000) \
  --filter-pattern "ERROR"

# Check alarm states
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'MetricAlarms[*].{Name:AlarmName,Reason:StateReason}'
```

### 5. Summarize Findings

After gathering data:
1. State what was found (errors, misconfigurations, resource states)
2. Identify the root cause if determinable
3. Propose remediation steps with specific commands
4. Flag any destructive remediation for user confirmation before running

## Quick Diagnostic Checklist

For any AWS issue, run through:

- [ ] Is the resource in the expected state? (running, available, active)
- [ ] Are there recent CloudWatch alarms firing?
- [ ] Are there error logs in the relevant log group?
- [ ] Are IAM permissions sufficient? (check for AccessDenied errors)
- [ ] Is the resource in the correct VPC/subnet/security group?
- [ ] Are there resource limits being hit? (quotas, connections, concurrency)

## Common Error Patterns

| Error | Likely Cause | First Check |
|-------|-------------|-------------|
| `AccessDeniedException` | IAM permissions | Check policy attached to role/user |
| `InvalidClientTokenId` | Wrong region or expired credentials | `aws sts get-caller-identity` |
| Connection timeout | Security group / NACL | Check inbound rules on SG |
| `ThrottlingException` | API rate limit | Retry with exponential backoff; check quotas |
| `ResourceNotFoundException` | Wrong name/region | Verify resource exists in region |

## Additional Resources

### Reference Files

For service-specific CLI commands and investigation patterns:
- **`references/aws-services.md`** - Detailed commands for EC2, RDS, Lambda, ECS, S3, DynamoDB, VPC, ALB, CloudFront, CloudWatch
- **`references/iam-debugging.md`** - IAM policy analysis, permission boundary debugging, access denied investigation

### Examples

- **`examples/investigate-rds.sh`** - Example RDS connection investigation script
- **`examples/investigate-lambda.sh`** - Example Lambda error investigation script
