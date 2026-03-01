#!/usr/bin/env bash
# Example: Investigate Kubernetes service connectivity issues
# Usage: CONTEXT=prod-cluster NS=production bash investigate-networking.sh my-service

set -euo pipefail

SERVICE="${1:?Usage: $0 <service-name>}"
NS="${NS:-default}"
CONTEXT="${CONTEXT:-$(kubectl config current-context)}"

echo "=== Context: $CONTEXT | Namespace: $NS ==="
kubectl config use-context "$CONTEXT"

echo ""
echo "=== Service Details ==="
kubectl get svc "$SERVICE" -n "$NS" -o wide
echo ""
kubectl describe svc "$SERVICE" -n "$NS" | grep -E "Selector|Port|Endpoints|Type|LoadBalancer"

echo ""
echo "=== Endpoint Health ==="
kubectl get endpoints "$SERVICE" -n "$NS"
ENDPOINT_COUNT=$(kubectl get endpoints "$SERVICE" -n "$NS" -o jsonpath='{.subsets[*].addresses}' 2>/dev/null | tr ' ' '\n' | grep -c ip || echo "0")
if [ "$ENDPOINT_COUNT" -eq 0 ]; then
  echo "WARNING: No healthy endpoints. Service selector may not match any pods."
  echo ""
  echo "=== Service Selector ==="
  kubectl get svc "$SERVICE" -n "$NS" -o jsonpath='{.spec.selector}' && echo ""
  echo ""
  echo "=== Pods in Namespace (with labels) ==="
  kubectl get pods -n "$NS" --show-labels
fi

echo ""
echo "=== DNS Resolution Test ==="
kubectl run dns-test-$$ --image=busybox:1.28 --rm -it --restart=Never \
  --namespace "$NS" -- nslookup "${SERVICE}.${NS}.svc.cluster.local" 2>/dev/null || true

echo ""
echo "=== Network Policies in Namespace ==="
NP_COUNT=$(kubectl get networkpolicies -n "$NS" --no-headers 2>/dev/null | wc -l)
if [ "$NP_COUNT" -gt 0 ]; then
  echo "Found $NP_COUNT NetworkPolicies - these may be restricting traffic:"
  kubectl get networkpolicies -n "$NS"
else
  echo "No NetworkPolicies in $NS - no policy-based blocking"
fi

echo ""
echo "=== Recent Warning Events ==="
kubectl get events -n "$NS" \
  --field-selector "type=Warning,involvedObject.name=$SERVICE" \
  --sort-by='.lastTimestamp' 2>/dev/null | tail -10 || \
kubectl get events -n "$NS" --field-selector type=Warning --sort-by='.lastTimestamp' | tail -10
