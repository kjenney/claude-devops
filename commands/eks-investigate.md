---
name: eks-investigate
description: Investigate Kubernetes/EKS issues by running automated diagnostics.
argument-hint: "[optional: brief description of the issue]"
allowed-tools:
  - Agent
---

Launch the EKS investigator agent to investigate a Kubernetes issue.

The agent will ask for:
- **Issue type** (deployment, networking, node, ingress)
- **Resource name** (deployment name, service name, node name, etc.)
- **kubectl context** (e.g., docker-desktop, eks-prod)
- **Namespace** (defaults to default)

Then run:
```bash
PLUGIN_DIR="$(dirname "$(find ~ -name ".claude-plugin" -type d 2>/dev/null | grep devops-claude-plugin)" 2>/dev/null)" && \
bash "$PLUGIN_DIR/skills/eks-troubleshooting/run-investigation.sh" "<issue-type>" "<resource-name>" "<context>" "<namespace>"
```
