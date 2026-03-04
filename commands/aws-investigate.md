---
name: aws-investigate
description: Interactively investigate and troubleshoot an AWS resource issue. Asks for the problem description, AWS profile, and region, then systematically diagnoses the issue using the AWS CLI.
argument-hint: "[optional: brief description of the issue]"
allowed-tools:
  - Bash
  - Read
---

# AWS Investigation

The user wants to troubleshoot an AWS resource issue. Conduct a systematic investigation using the AWS CLI with automated service detection.

## Step 1: Gather Information

Ask the user for the following information (all in one message, not separately):

1. **What is the problem?** (error message, symptom, alert name, or affected service)
2. **Which AWS CLI profile** should be used? (list available profiles with `aws configure list-profiles` if helpful)
3. **Which AWS region?** (e.g., `us-east-1`, `eu-west-1`)
4. **Resource name or identifier** (function name, database instance ID, etc.) - if applicable
5. **Approximate time window** when the issue started (for log queries)

If the user provided a description as a command argument, use it as the starting point for question 1 and still ask for profile and region.

## Step 2: Automatic Investigation

Once the profile and region are confirmed, run the automated investigation script which will:

1. Verify AWS access
2. **Automatically detect** the service type (Lambda, RDS, EC2, etc.) from the problem description
3. Run the appropriate example investigation script if available
4. Provide service-specific diagnostics with CloudWatch data

```bash
bash skills/aws-troubleshooting/run-investigation.sh "<problem>" "<profile>" "<region>" "[resource-name]"
```

**Supported automated investigations:**
- **Lambda**: Detects function config, recent errors, throttles, concurrency
- **RDS**: Checks instance status, events, connection counts, storage, CPU
- Other services: Manual commands guided by references/aws-services.md

## Step 3: Investigate Further (If Needed)

If automated investigation isn't available for the service type or you need deeper analysis:

Based on the problem description, determine which AWS service is involved and follow the appropriate investigation path:

- **EC2 / Auto Scaling**: Check instance state, status checks, ASG activities
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
- The investigation script auto-detects service type from the problem description keywords (e.g., "Lambda", "RDS", "database")
