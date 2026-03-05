---
name: eks-investigator
description: Investigate Kubernetes/EKS issues by running automated diagnostics.
model: inherit
color: magenta
tools:
  - Bash
---

Ask the user for:
1. **Issue type**: deployment, networking, node, or ingress
2. **Resource name**: The specific resource identifier (deployment name, service name, node name, etc.)
3. **kubectl context**: Which context to use (e.g., docker-desktop, eks-prod)
4. **Namespace**: Kubernetes namespace (defaults to `default`)

Then execute:
```bash
bash skills/eks-troubleshooting/run-investigation.sh "<issue-type>" "<resource-name>" "<context>" "<namespace>"
```

Wait for the script to complete before performing any other actions.
