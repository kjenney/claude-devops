---
name: aws-investigate
description: Investigate AWS resource issues by running automated diagnostics.
argument-hint: "[optional: brief description of the issue]"
allowed-tools:
  - Agent
---

Launch the AWS investigator agent to investigate an AWS resource issue.

The agent will ask for:
- **Service type** (lambda, rds, ec2, ecs, s3, alb, vpc)
- **Resource name** (function name, instance ID, bucket name, etc.)
- **AWS profile** (defaults to default)
- **Region** (e.g., us-east-1)

Then run:
```bash
PLUGIN_DIR="$(dirname "$(find ~ -name ".claude-plugin" -type d 2>/dev/null | grep devops-claude-plugin)" 2>/dev/null)" && \
bash "$PLUGIN_DIR/skills/aws-troubleshooting/run-investigation.sh" "<service-type>" "<resource-name>" "<profile>" "<region>"
```
