---
name: aws-investigate
description: Interactively investigate and troubleshoot an AWS resource issue. Asks for the problem description, AWS profile, and region, then systematically diagnoses the issue using the AWS CLI.
argument-hint: "[optional: brief description of the issue]"
allowed-tools:
  - Agent
---

# AWS Investigation

The user wants to troubleshoot an AWS resource issue using automated investigation.

Launch the AWS investigator agent to handle the investigation. The agent will:
1. Ask for the AWS service type (lambda, rds, ec2, ecs, s3, alb, vpc)
2. Gather resource details and AWS credentials
3. Verify AWS access
4. Run the appropriate investigation script for that service type
5. Provide findings and recommendations

Use the Agent tool to launch the aws-investigator agent with the user's issue description.

## How It Works

The agent will guide you through the investigation process:

```bash
bash skills/aws-troubleshooting/run-investigation.sh "<service-type>" "<resource-name>" "<profile>" "<region>"
```

**Parameters:**
- `service-type`: One of: `lambda`, `rds`, `ec2`, `ecs`, `s3`, `alb`, `vpc`
- `resource-name`: The specific resource to investigate (function name, database ID, instance ID, etc.)
- `profile`: AWS CLI profile to use (or `default`)
- `region`: AWS region (e.g., `us-east-1`, `eu-west-1`)

**What the script does:**
1. Validates the service type
2. Verifies AWS credentials with the specified profile and region
3. Calls the appropriate example investigation script for that service type
4. Provides diagnostic output for your issue

**Supported service types and what they investigate:**
- **lambda**: Lambda function concurrency, throttling, errors, logs
- **rds**: Database instance status, connections, storage, performance
- **ec2**: Instance status, system checks, CPU/network metrics
- **ecs**: ECS service status, task state, container logs
- **s3**: Bucket configuration, access, replication status
- **alb**: Load balancer health, target groups, listener status
- **vpc**: VPC security groups, network ACLs, route tables
