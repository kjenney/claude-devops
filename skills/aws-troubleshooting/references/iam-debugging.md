# IAM Debugging Guide

## Diagnosing AccessDenied Errors

When encountering an `AccessDeniedException` or `Access Denied` error:

### 1. Identify the Principal

```bash
# Who is making the call?
aws sts get-caller-identity

# For EC2 instance role
aws sts get-caller-identity --profile instance-profile
```

### 2. Find the Policy Attached

```bash
# List policies attached to a role
aws iam list-attached-role-policies --role-name <role>

# List inline policies
aws iam list-role-policies --role-name <role>

# Get policy document
aws iam get-policy --policy-arn <arn>
aws iam get-policy-version \
  --policy-arn <arn> \
  --version-id $(aws iam get-policy --policy-arn <arn> --query 'Policy.DefaultVersionId' --output text)

# Get inline policy document
aws iam get-role-policy --role-name <role> --policy-name <name>
```

### 3. Check Permission Boundaries

```bash
aws iam get-role --role-name <role> \
  --query 'Role.PermissionsBoundary'
```

### 4. Check SCPs (Service Control Policies in AWS Organizations)

```bash
# List policies affecting account
aws organizations list-policies-for-target \
  --target-id <account-id> \
  --filter SERVICE_CONTROL_POLICY

# Get SCP document
aws organizations describe-policy --policy-id <id>
```

### 5. Simulate IAM Policies

```bash
# Test if a principal can perform an action
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::<account>:role/<role> \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::<bucket>/<key> \
  --query 'EvaluationResults[*].{Action:EvalActionName,Decision:EvalDecision,Reason:EvalDecisionDetails}'
```

### 6. Check CloudTrail for the Denied Event

```bash
# Look up recent access denied events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=<ActionName> \
  --max-results 10 \
  --query 'Events[*].{Time:EventTime,User:Username,Error:Resources}'
```

## Common IAM Issues

| Issue | Symptom | Resolution |
|-------|---------|------------|
| Missing action | `AccessDenied` on specific API call | Add action to policy |
| Resource not in policy | `AccessDenied` even with action allowed | Check resource ARN in policy |
| Condition mismatch | `AccessDenied` intermittently | Check policy conditions (ip, time, tags) |
| SCP blocking | `AccessDenied` despite correct role policy | Check organization SCPs |
| Permission boundary | Permissions appear correct but denied | Check if boundary limits the role |
| Cross-account issue | `AccessDenied` from another account | Check trust relationship and resource policy |

## IAM Role Trust Relationships

```bash
# Check who can assume a role
aws iam get-role --role-name <role> \
  --query 'Role.AssumeRolePolicyDocument'

# Check if a service can assume the role
# Trust policy should include: "Principal": {"Service": "lambda.amazonaws.com"}
```

## Resource Policies

Some services have resource-based policies that also affect access:

```bash
# S3 bucket policy
aws s3api get-bucket-policy --bucket <bucket>

# Lambda resource policy
aws lambda get-policy --function-name <name>

# KMS key policy
aws kms get-key-policy --key-id <id> --policy-name default

# SQS queue policy
aws sqs get-queue-attributes \
  --queue-url <url> \
  --attribute-names Policy
```
