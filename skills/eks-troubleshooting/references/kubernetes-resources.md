# Kubernetes Resource Investigation Commands

## Deployments & ReplicaSets

```bash
# Check deployment status and rollout
kubectl get deployment <name> -n $NS -o wide
kubectl rollout status deployment/<name> -n $NS
kubectl rollout history deployment/<name> -n $NS

# Describe deployment (see conditions, events)
kubectl describe deployment <name> -n $NS

# Check ReplicaSet status (current vs desired)
kubectl get rs -n $NS -l app=<label>
kubectl describe rs <rs-name> -n $NS

# View deployment YAML to check resource limits, image, env
kubectl get deployment <name> -n $NS -o yaml

# Check pod template labels (used by service selector)
kubectl get deployment <name> -n $NS -o jsonpath='{.spec.selector.matchLabels}'

# Rollback to previous version
# (CONFIRM WITH USER before running)
kubectl rollout undo deployment/<name> -n $NS
```

## Pods

```bash
# Get all pods with status and node
kubectl get pods -n $NS -o wide

# Filter by label
kubectl get pods -n $NS -l app=<label> -o wide

# Get pods sorted by restart count
kubectl get pods -n $NS --sort-by='.status.containerStatuses[0].restartCount'

# Describe pod (events, resource usage, init containers)
kubectl describe pod <pod-name> -n $NS

# Get current logs
kubectl logs <pod-name> -n $NS -c <container> --tail=200

# Follow logs in real time
kubectl logs <pod-name> -n $NS -c <container> -f

# Get previous container logs (after restart/crash)
kubectl logs <pod-name> -n $NS -c <container> --previous --tail=200

# Execute into container for debugging
kubectl exec -it <pod-name> -n $NS -c <container> -- /bin/sh

# Check resource usage
kubectl top pod <pod-name> -n $NS --containers

# Get pod YAML to check volumes, env, resources
kubectl get pod <pod-name> -n $NS -o yaml
```

## Services & Endpoints

```bash
# List services
kubectl get svc -n $NS

# Describe service (check selector, ports, type)
kubectl describe svc <name> -n $NS

# Check endpoints (are pods matched by selector?)
kubectl get endpoints <name> -n $NS
kubectl describe endpoints <name> -n $NS

# If endpoints are empty, the service selector doesn't match any pods
# Compare: service selector vs pod labels
kubectl get svc <name> -n $NS -o jsonpath='{.spec.selector}'
kubectl get pods -n $NS --show-labels | grep <expected-label>

# Test service DNS from inside cluster
kubectl run debug-pod --image=busybox --rm -it --restart=Never -- \
  nslookup <service-name>.<namespace>.svc.cluster.local
```

## Ingress

```bash
# List ingresses
kubectl get ingress -n $NS
kubectl get ingress <name> -n $NS -o wide

# Describe ingress (check rules, backend, annotations)
kubectl describe ingress <name> -n $NS

# Check ingress controller logs (usually in ingress-nginx namespace)
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=100

# Check AWS Load Balancer Controller logs (for ALB ingress)
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=100

# Check ingress class
kubectl get ingressclass

# Check annotations on ingress (common issues)
kubectl get ingress <name> -n $NS -o jsonpath='{.metadata.annotations}'
```

## Nodes

```bash
# Get node status
kubectl get nodes -o wide
kubectl get nodes --show-labels

# Describe a node (check conditions, capacity, allocatable, events)
kubectl describe node <node-name>

# Check resource pressure on nodes
kubectl top nodes

# List pods on a specific node
kubectl get pods -A --field-selector spec.nodeName=<node-name>

# Check node taints (may prevent pod scheduling)
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# Check node conditions
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{range .status.conditions[*]}{.type}={.status}{"\t"}{end}{"\n"}{end}'

# Cordon/drain node (CONFIRM WITH USER)
kubectl cordon <node-name>
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

## HPA (Horizontal Pod Autoscaler)

```bash
# Check HPA status
kubectl get hpa -n $NS
kubectl describe hpa <name> -n $NS

# If HPA shows <unknown> for current metrics:
# 1. Verify metrics-server is running
kubectl get pods -n kube-system | grep metrics-server
kubectl top pods -n $NS  # This should work if metrics-server is healthy

# 2. Check target deployment has resource requests set
kubectl get deployment <name> -n $NS -o jsonpath='{.spec.template.spec.containers[*].resources}'
```

## Resource Quotas & LimitRanges

```bash
# Check namespace quotas (usage vs limit)
kubectl describe resourcequota -n $NS

# Check namespace LimitRange (default requests/limits)
kubectl describe limitrange -n $NS

# Check if a pod was rejected due to quota
kubectl get events -n $NS --field-selector reason=FailedCreate

# View all resource usage in namespace
kubectl get pods -n $NS -o json | jq '[.items[].spec.containers[].resources]'
```

## Cluster Events

```bash
# Get all events in namespace sorted by time
kubectl get events -n $NS --sort-by='.lastTimestamp'

# Get Warning events only
kubectl get events -n $NS --field-selector type=Warning --sort-by='.lastTimestamp'

# Watch events live
kubectl get events -n $NS -w

# Get events for a specific object
kubectl get events -n $NS --field-selector involvedObject.name=<pod-name>
```

## RBAC / Permissions

```bash
# Check what current user can do
kubectl auth can-i --list -n $NS

# Check if service account can do specific action
kubectl auth can-i get pods \
  --as=system:serviceaccount:<namespace>:<sa-name> -n $NS

# Get service account details
kubectl get serviceaccount <name> -n $NS -o yaml
kubectl get clusterrolebinding,rolebinding -A | grep <sa-name>
```

## Cluster Autoscaler

```bash
# Check CA logs for scaling decisions
kubectl logs -n kube-system -l app=cluster-autoscaler --tail=100 | grep -E "scale|expander|ERROR"

# Check CA status configmap
kubectl get configmap cluster-autoscaler-status -n kube-system -o yaml
```
