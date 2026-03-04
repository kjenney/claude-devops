---
name: eks-investigate
description: Interactively investigate and troubleshoot an EKS or Kubernetes service issue. Asks for the problem description, kubectl context, and namespace, then systematically diagnoses pods, deployments, services, ingress, nodes, and resource constraints.
argument-hint: "[optional: brief description of the issue]"
allowed-tools:
  - Bash
  - Read
---

# EKS Investigation

The user wants to troubleshoot a Kubernetes or EKS issue. Conduct a systematic investigation using kubectl with automated issue detection.

## Step 1: Gather Information

Ask the user for the following (in one message):

1. **What is the problem?** (pod crashing, service unreachable, deployment stuck, node NotReady, etc.)
2. **Which kubectl context?** (list available with `kubectl config get-contexts` if helpful)
3. **Which namespace?** (e.g., `production`, `staging`, `default`)
4. **Resource name** (deployment name, pod name, service name — or "unknown, help me find it")

If the user provided an argument, use it as context for the problem description.

## Step 2: Automatic Investigation

Once context and namespace are known, run the automated investigation script which will:

1. Verify kubectl access and context
2. **Automatically detect** the issue type (deployment, networking, node, ingress) from the problem description
3. Run the appropriate example investigation script if available
4. Provide targeted diagnostics

```bash
bash skills/eks-troubleshooting/run-investigation.sh "<problem>" "<context>" "<namespace>" "[resource-name]"
```

**Supported automated investigations:**
- **Deployment issues**: Pod crashes, CrashLoopBackOff, image pull errors, stuck rollouts
- **Networking issues**: Service connectivity, DNS resolution, endpoints, network policies
- Other issues: Manual commands guided by references/kubernetes-resources.md

## Step 3: Further Investigation (If Needed)

If automated investigation isn't available or you need deeper analysis, start with a broad view, then narrow down:

### Always Start With:
```bash
kubectl get pods -n $NS -o wide
kubectl get events -n $NS --sort-by='.lastTimestamp' | tail -20
```

### Then Based on the Symptom:

**Pod crashing / CrashLoopBackOff**:
- Describe the pod: `kubectl describe pod <name> -n $NS`
- Get current logs: `kubectl logs <name> -n $NS --tail=100`
- Get previous logs: `kubectl logs <name> -n $NS --previous --tail=100`
- Check resource limits vs usage: `kubectl top pod <name> -n $NS`

**Deployment stuck / image pull errors**:
- Check rollout: `kubectl rollout status deployment/<name> -n $NS`
- Describe deployment: `kubectl describe deployment <name> -n $NS`
- Check pod describe for image pull errors

**Service not reachable**:
- Check endpoints: `kubectl get endpoints <service> -n $NS`
- Describe service: `kubectl describe svc <service> -n $NS`
- Verify selector matches pods: compare service selector with pod labels
- Check network policies: `kubectl get networkpolicies -n $NS`

**Node NotReady**:
- Describe node: `kubectl describe node <node-name>`
- Check node conditions and resource pressure
- Look for DaemonSet failures on the node

**Ingress not routing**:
- Check ingress: `kubectl describe ingress <name> -n $NS`
- Check ingress controller logs
- Verify backend service and endpoints are healthy

**HPA not scaling**:
- Check HPA: `kubectl describe hpa -n $NS`
- Verify metrics-server: `kubectl top pods -n $NS`
- Check deployment has resource requests set

Use `eks-troubleshooting` skill for detailed commands.

## Step 4: Report Findings

Present a clear summary:
1. **Resource state** (what pods/services are in what state)
2. **What was found** (error messages, events, resource issues)
3. **Root cause** (if determinable)
4. **Recommended fix** with specific kubectl commands

**Important**: Before running any write operations (delete pod, scale deployment, drain node), describe the action and ask the user to confirm.

## Tips

- `kubectl describe` is almost always the first useful command after `get`
- Check events in the namespace - they often contain the clearest error messages
- For OOMKilled pods, increase `resources.limits.memory` and verify with `kubectl top`
- For Pending pods, check node capacity and any taints/tolerations issues
