---
name: EKS Troubleshooting
description: This skill should be used when the user asks to "troubleshoot EKS", "investigate Kubernetes service", "debug pod crash", "check pod logs", "pod is OOMKilled", "deployment is stuck", "service not reachable", "node is NotReady", "ingress not routing", "HPA not scaling", "check namespace quotas", "debug kubectl", or mentions Kubernetes resource errors, CrashLoopBackOff, ImagePullBackOff, Pending pods, or EKS cluster issues. Provides systematic Kubernetes investigation workflows using kubectl.
---

# EKS Troubleshooting

A structured approach to diagnosing and resolving issues in Amazon EKS clusters using kubectl. Covers workloads (pods, deployments), networking (services, ingress, DNS), nodes and scaling (HPA, cluster autoscaler), and resource management (quotas, limits).

## Prerequisites

Ensure the following are available:
- `kubectl` installed and working
- Access to the relevant cluster context (`kubectl config get-contexts`)
- Appropriate RBAC permissions for the namespaces being investigated

## Core Workflow

### 1. Gather Context

Collect before running commands:
- **What is broken**: Symptom or error message
- **Which cluster**: EKS cluster name and context
- **Which namespace**: Kubernetes namespace of the affected resources
- **Which resource**: Deployment, service, pod, ingress name

Ask the user: "Which kubectl context and namespace should I use?" then set:

```bash
kubectl config use-context <context-name>
export NS=<namespace>
```

### 2. Verify Cluster Access

```bash
kubectl cluster-info
kubectl config current-context
kubectl get nodes -o wide
```

### 3. Investigate by Resource Type

Use the patterns in `references/kubernetes-resources.md` based on what is broken.

### 4. Systematic Pod Investigation

For any pod issue, run this sequence:

```bash
# Step 1: Check pod status
kubectl get pods -n $NS -o wide

# Step 2: Describe the problematic pod
kubectl describe pod <pod-name> -n $NS

# Step 3: Get current logs
kubectl logs <pod-name> -n $NS --tail=100

# Step 4: Get previous container logs (if pod restarted)
kubectl logs <pod-name> -n $NS --previous --tail=100

# Step 5: Check events in namespace
kubectl get events -n $NS --sort-by='.lastTimestamp' | tail -30
```

### 5. Common Pod Status Meanings

| Status | Meaning | First Action |
|--------|---------|-------------|
| `CrashLoopBackOff` | Container exits repeatedly | Check logs with `--previous` |
| `OOMKilled` | Memory limit exceeded | Increase `resources.limits.memory` |
| `ImagePullBackOff` | Cannot pull container image | Check image name, tag, registry auth |
| `Pending` | Cannot be scheduled | Check node capacity, taints, resource requests |
| `Terminating` | Stuck during deletion | Check for finalizers |
| `Error` | Container exited with error | Check exit code in `describe`, check logs |
| `Init:Error` | Init container failed | Check init container logs |

### 6. Summarize Findings

After gathering data:
1. Identify the root cause (resource exhaustion, image issue, config error, networking, scheduling)
2. Propose remediation with specific kubectl commands
3. Flag destructive operations (delete pod, scale down) for user confirmation

## Additional Resources

### Reference Files

- **`references/kubernetes-resources.md`** - Detailed kubectl commands for deployments, services, ingress, nodes, HPA, quotas, RBAC
- **`references/networking-debug.md`** - Service connectivity, DNS, and ingress debugging

### Examples

- **`examples/investigate-deployment.sh`** - Full deployment investigation script
- **`examples/investigate-networking.sh`** - Service and ingress connectivity checks
