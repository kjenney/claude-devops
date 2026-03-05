---
name: AWS Troubleshooting
description: Investigate AWS resource issues by running run-investigation.sh with the service type, resource name, profile, and region.
---

# AWS Troubleshooting Skill

The `/aws-investigate` command and `aws-investigator` agent run the automated investigation orchestrator:

```bash
bash skills/aws-troubleshooting/run-investigation.sh "<service-type>" "<resource-name>" "<profile>" "<region>"
```

## Supported Service Types

- `lambda` - Lambda function concurrency, errors, throttling, logs
- `rds` - RDS instance status, connections, storage, performance
- `ec2` - EC2 instance status, system checks, CPU/network metrics
- `ecs` - ECS service status, task state, container logs
- `s3` - S3 bucket configuration, access, replication status
- `alb` - ALB health, target groups, listener status
- `vpc` - VPC security groups, network ACLs, route tables

## Usage

1. Run `/aws-investigate` command
2. Agent asks for service type, resource name, AWS profile, and region
3. Agent executes the investigation script
4. Wait for results

## Example Scripts

- `examples/investigate-lambda.sh` - Queries Lambda function metrics, errors, logs
- `examples/investigate-rds.sh` - Queries RDS instance metrics, connections, events
