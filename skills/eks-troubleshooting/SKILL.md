---
name: EKS Troubleshooting
description: Investigate Kubernetes/EKS issues by running run-investigation.sh with the issue type, resource name, kubectl context, and namespace.
---

# EKS Troubleshooting Skill

The `/eks-investigate` command and `eks-investigator` agent run the automated investigation orchestrator:

```bash
bash skills/eks-troubleshooting/run-investigation.sh "<issue-type>" "<resource-name>" "<context>" "<namespace>"
```

## Supported Issue Types

- `deployment` - Pod status, rollout status, events, restart counts, resource usage
- `networking` - Service details, endpoints, DNS resolution, network policies
- `node` - Node status, conditions, resource pressure, taints/tolerations
- `ingress` - Ingress configuration, backend services, certificate status

## Usage

1. Run `/eks-investigate` command
2. Agent asks for issue type, resource name, kubectl context, and namespace
3. Agent executes the investigation script
4. Wait for results

## Example Scripts

- `examples/investigate-deployment.sh` - Queries deployment status, events, pod logs
- `examples/investigate-networking.sh` - Queries service endpoints, DNS, network policies
