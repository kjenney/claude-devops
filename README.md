# claude-devops

A Claude Code plugin for performing DevOps troubleshooting tasks, including:

* Connecting to AWS to troubleshoot resources
* Connecting to EKS to troubleshoot service issues
* Connecting to Datadog to troubleshoot service logs and metrics

## Features

### Skills (Auto-Activating Knowledge)
- **aws-troubleshooting** — Systematic AWS investigation patterns for EC2, RDS, Lambda, ECS, S3, VPC, ALB, CloudWatch
- **eks-troubleshooting** — Kubernetes/EKS investigation patterns for pods, deployments, services, ingress, nodes, HPA, quotas
- **datadog-troubleshooting** — Datadog API query patterns for logs, metrics, monitors, and APM traces

### Commands (Slash Commands)
- `/devops:aws-investigate` — Interactively troubleshoot an AWS resource issue
- `/devops:eks-investigate` — Interactively troubleshoot an EKS/Kubernetes service issue
- `/devops:datadog-query` — Query Datadog for service logs, metrics, monitors, and APM

### Agents (Autonomous Troubleshooters)
- **aws-investigator** — Proactively investigates AWS resource errors and anomalies
- **eks-investigator** — Proactively investigates Kubernetes pod failures and service issues
- **datadog-investigator** — Proactively queries Datadog for service health signals

## Prerequisites

### AWS
- AWS CLI installed: `aws --version`
- Named profiles configured: `~/.aws/config`
- Appropriate IAM permissions for the resources you investigate

### EKS
- `kubectl` installed: `kubectl version`
- Kubeconfig with cluster contexts: `kubectl config get-contexts`
- RBAC permissions for target namespaces

### Datadog
- Datadog API Key and Application Key
- Set environment variables before using Datadog commands/agents:
  ```bash
  export DD_API_KEY="<your-api-key>"
  export DD_APP_KEY="<your-app-key>"
  export DD_SITE="datadoghq.com"  # or datadoghq.eu for EU
  ```
- `jq` installed for JSON parsing: `brew install jq` (macOS) or `apt install jq`

## Testing

The plugin includes a test suite covering all example scripts.

**Prerequisites:**
```bash
brew install shellcheck bats-core
```

**Run all tests:**
```bash
bash tests/run-tests.sh
```

**Options:**
```bash
bash tests/run-tests.sh --lint-only   # shellcheck static analysis only
bash tests/run-tests.sh --test-only   # bats unit tests only (uses mocked aws/kubectl/curl)
```

The tests use mock binaries in `tests/mocks/` that return fixture data, so no real AWS credentials, EKS cluster access, or Datadog API keys are needed to run the tests.

## Installation

```bash
# Test locally
claude --plugin-dir /path/to/devops-plugin

# Or copy to project for project-level use
cp -r /path/to/devops-plugin/.claude-plugin /path/to/your-project/
```

## Usage

### AWS Troubleshooting

Trigger the skill automatically by describing an AWS issue:
> "Our RDS instance prod-db is showing connection errors"
> "Lambda function payment-processor is throttling"

Or run the command explicitly:
```
/devops:aws-investigate
```

### EKS Troubleshooting

Trigger automatically:
> "My pods are OOMKilled in the production namespace"
> "The checkout service deployment is stuck"

Or run the command:
```
/devops:eks-investigate
```

### Datadog Investigation

First set credentials:
```bash
export DD_API_KEY="..." && export DD_APP_KEY="..."
```

Trigger automatically:
> "Check Datadog for errors on the payment service"
> "Are any production monitors firing right now?"

Or run the command:
```
/devops:datadog-query
```

## Plugin Structure

```
devops-plugin/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── aws-troubleshooting/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   │   ├── aws-services.md       # EC2, RDS, Lambda, ECS, S3, VPC, ALB, DynamoDB commands
│   │   │   └── iam-debugging.md      # IAM policy analysis and access denied debugging
│   │   └── examples/
│   │       ├── investigate-rds.sh
│   │       └── investigate-lambda.sh
│   ├── eks-troubleshooting/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   │   ├── kubernetes-resources.md  # kubectl commands for all resource types
│   │   │   └── networking-debug.md      # DNS, service, ingress, CNI debugging
│   │   └── examples/
│   │       ├── investigate-deployment.sh
│   │       └── investigate-networking.sh
│   └── datadog-troubleshooting/
│       ├── SKILL.md
│       ├── references/
│       │   ├── datadog-api.md           # Full Datadog API call reference
│       │   └── log-query-syntax.md      # Log search query syntax and examples
│       └── examples/
│           └── investigate-service.sh
├── commands/
│   ├── aws-investigate.md
│   ├── eks-investigate.md
│   └── datadog-query.md
├── agents/
│   ├── aws-investigator.md
│   ├── eks-investigator.md
│   └── datadog-investigator.md
├── .gitignore
└── README.md
```
