#!/usr/bin/env bash
# Example: Investigate a Kubernetes deployment issue
# Usage: CONTEXT=prod-cluster NS=production bash investigate-deployment.sh my-service

set -euo pipefail

DEPLOYMENT="${1:?Usage: $0 <deployment-name>}"
NS="${NS:-default}"
CONTEXT="${CONTEXT:-$(kubectl config current-context)}"

echo "=== Context: $CONTEXT | Namespace: $NS ==="
kubectl config use-context "$CONTEXT"

echo ""
echo "=== Deployment Status ==="
kubectl get deployment "$DEPLOYMENT" -n "$NS" -o wide

echo ""
echo "=== Rollout Status ==="
kubectl rollout status deployment/"$DEPLOYMENT" -n "$NS" --timeout=5s 2>&1 || true

echo ""
echo "=== Deployment Events ==="
kubectl describe deployment "$DEPLOYMENT" -n "$NS" | grep -A 20 "Events:"

echo ""
echo "=== Pods ==="
kubectl get pods -n "$NS" -l "$(kubectl get deployment "$DEPLOYMENT" -n "$NS" -o jsonpath='{range .spec.selector.matchLabels}{@k}={@v},{end}' | sed 's/,$//')" -o wide

echo ""
echo "=== Pod Restart Counts ==="
kubectl get pods -n "$NS" --sort-by='.status.containerStatuses[0].restartCount' \
  -o custom-columns='NAME:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount,STATUS:.status.phase'

echo ""
echo "=== Recent Namespace Events (Warnings) ==="
kubectl get events -n "$NS" --field-selector type=Warning --sort-by='.lastTimestamp' | tail -20

echo ""
echo "=== Resource Usage ==="
kubectl top pods -n "$NS" -l "app=$DEPLOYMENT" 2>/dev/null || echo "metrics-server not available or no matching pods"
