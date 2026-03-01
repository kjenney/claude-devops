---
name: aws-investigate
description: Interactively investigate and troubleshoot an AWS resource issue. Asks for the problem description, AWS profile, and region, then systematically diagnoses the issue using the AWS CLI.
argument-hint: "[optional: brief description of the issue]"
allowed-tools:
  - Bash
  - Read
---

# AWS Investigation

The user wants to troubleshoot an AWS resource issue. Conduct a systematic investigation using the AWS CLI.

## Step 1: Gather Information

Ask the user for the following information (all in one message, not separately):

1. **What is the problem?** (error message, symptom, alert name, or affected service)
2. **Which AWS CLI profile** should be used? (list available profiles with `aws configure list-profiles` if helpful)
3. **Which AWS region?** (e.g., `us-east-1`, `eu-west-1`)
4. **Approximate time window** when the issue started (for log queries)

If the user provided a description as a command argument, use it as the starting point for question 1 and still ask for profile and region.

## Step 2: Set Environment

Once the profile and region are confirmed, set them for all subsequent commands:

```bash
export AWS_PROFILE=<profile>
export AWS_DEFAULT_REGION=<region>
```

Verify access:
```bash
aws sts get-caller-identity
```

If access fails, report the error and ask the user to check their credentials.

## Step 3: Investigate

Based on the problem description, determine which AWS service is involved and follow the appropriate investigation path:

- **EC2 / Auto Scaling**: Check instance state, status checks, ASG activities
- **RDS / Aurora**: Check instance status, recent events, connection counts, storage
- **Lambda**: Check function config, recent errors in logs, throttles, concurrency
- **ECS / Fargate**: Check service status, stopped task reasons, container logs
- **S3**: Check bucket policy, ACL, public access block settings
- **VPC / Networking**: Check security groups, NACLs, route tables
- **ALB**: Check target group health, listener rules
- **CloudWatch / Alarms**: Check alarm states, recent state changes, log insights

Always check CloudWatch for alarms and logs related to the affected resource.

Use the `aws-troubleshooting` skill for detailed commands for each service type.

## Step 4: Report Findings

Present a clear summary:
1. **Current state** of the resource (running/stopped/degraded)
2. **What was found** (errors, misconfigurations, capacity issues)
3. **Root cause** (if determinable)
4. **Recommended fix** with specific commands

**Important**: Before running any write/mutating commands (restart, update, delete), describe the intended action and ask the user to confirm.

## Tips

- Use `--output table` for human-readable AWS CLI output
- Add `--query` to filter only relevant fields
- For log searches, use CloudWatch Logs Insights for complex queries
- If a resource name is unknown, help the user discover it with list/describe commands first
