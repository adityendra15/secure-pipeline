#!/usr/bin/env bash
set -euo pipefail

echo "Pods before deletion:"
kubectl get pods -l app=secure-pipeline

POD="$(kubectl get pods -l app=secure-pipeline -o jsonpath='{.items[0].metadata.name}')"
echo
echo "Deleting pod: $POD"
kubectl delete pod "$POD"

echo
echo "Kubernetes is creating a replacement because the Deployment requires two replicas..."
kubectl wait --for=condition=available deployment/secure-pipeline --timeout=120s

echo
echo "Pods after self-healing:"
kubectl get pods -l app=secure-pipeline
