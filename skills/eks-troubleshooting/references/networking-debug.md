# Kubernetes Networking Debug Guide

## DNS Resolution Issues

```bash
# Test DNS from within the cluster
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- \
  nslookup kubernetes.default

# Test specific service DNS
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- \
  nslookup <service>.<namespace>.svc.cluster.local

# Check CoreDNS is running
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50

# Check CoreDNS configmap
kubectl get configmap coredns -n kube-system -o yaml
```

## Service Connectivity

```bash
# Check if service has healthy endpoints
kubectl get endpoints <service-name> -n $NS

# If endpoints are empty - check selector match:
# Service selector:
kubectl get svc <name> -n $NS -o jsonpath='{.spec.selector}'
# Pod labels:
kubectl get pods -n $NS --show-labels

# Test connectivity from a debug pod
kubectl run netcat-test --image=alpine --rm -it --restart=Never -- \
  /bin/sh -c "apk add netcat-openbsd && nc -zv <service-name>.<namespace>.svc.cluster.local <port>"

# Check if the pod's port is actually listening
kubectl exec <pod-name> -n $NS -- ss -tlnp
# or
kubectl exec <pod-name> -n $NS -- netstat -tlnp
```

## Network Policies

```bash
# Check if NetworkPolicies are blocking traffic
kubectl get networkpolicies -n $NS
kubectl describe networkpolicy <name> -n $NS

# Check if the source pod's namespace/labels match ingress rules
# Check if the destination pod's labels match egress rules
```

## ALB Ingress Debugging (AWS Load Balancer Controller)

```bash
# Check ingress has been provisioned with an address
kubectl get ingress <name> -n $NS
# ADDRESS column should show ALB DNS name

# Check ALB controller logs for errors
kubectl logs -n kube-system \
  -l app.kubernetes.io/name=aws-load-balancer-controller \
  --tail=100 | grep -E "ERROR|error|<ingress-name>"

# Common annotations to check:
kubectl get ingress <name> -n $NS -o yaml | grep -A 30 annotations

# Key annotations:
# kubernetes.io/ingress.class: alb
# alb.ingress.kubernetes.io/scheme: internet-facing (or internal)
# alb.ingress.kubernetes.io/target-type: ip (or instance)
# alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...

# Check target group health in AWS
aws elbv2 describe-target-groups \
  --query 'TargetGroups[?contains(TargetGroupName, `<service>`)].TargetGroupArn'
```

## NGINX Ingress Debugging

```bash
# Check nginx ingress controller pods
kubectl get pods -n ingress-nginx

# Get controller logs
kubectl logs -n ingress-nginx \
  -l app.kubernetes.io/name=ingress-nginx \
  --tail=200 | grep -E "error|upstream|<hostname>"

# Check nginx configuration for a host
kubectl exec -n ingress-nginx \
  $(kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -o name | head -1) \
  -- nginx -T | grep -A 20 "<hostname>"

# Check ingress class
kubectl get ingress <name> -n $NS -o jsonpath='{.spec.ingressClassName}'
kubectl get ingressclass
```

## EKS VPC CNI Issues

```bash
# Check aws-node (VPC CNI) pods
kubectl get pods -n kube-system -l k8s-app=aws-node

# Check VPC CNI logs
kubectl logs -n kube-system -l k8s-app=aws-node --tail=50 | grep -i error

# Check available IPs (warm pool)
kubectl describe node <node-name> | grep -A 10 "Allocatable"

# Check ENI limits for instance type (limits max pods per node)
# See: https://github.com/awslabs/amazon-eks-ami/blob/master/files/eni-max-pods.txt
```

## Pod-to-Pod Connectivity

```bash
# Get pod IPs
kubectl get pods -n $NS -o wide

# Test direct pod-to-pod connectivity
kubectl exec <source-pod> -n $NS -- \
  curl -s http://<destination-pod-ip>:<port>/health

# If using a sidecar (Istio/Envoy):
kubectl exec <pod-name> -n $NS -c istio-proxy -- \
  curl -s http://localhost:15000/clusters | grep <destination-service>
```
