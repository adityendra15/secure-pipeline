#!/usr/bin/env bash
set -euo pipefail

kubectl delete pod traffic-test --ignore-not-found >/dev/null 2>&1 || true

echo "Starting an in-cluster client that sends requests through the Kubernetes Service..."
kubectl run traffic-test \
  --image=curlimages/curl:8.10.1 \
  --restart=Never \
  --command -- sh -c '
    failed=0
    i=1
    while [ "$i" -le 30 ]; do
      if curl -fsS http://secure-pipeline/health/ready >/dev/null; then
        echo "request-$i OK"
      else
        echo "request-$i FAILED"
        failed=1
      fi
      i=$((i + 1))
      sleep 0.4
    done
    exit "$failed"
  '

sleep 2
echo "Triggering a real rolling update by changing the Pod template..."
kubectl set env deployment/secure-pipeline DEMO_RELEASE="$(date +%s)"
kubectl rollout status deployment/secure-pipeline --timeout=120s

kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/traffic-test --timeout=120s || {
  kubectl logs traffic-test || true
  exit 1
}

kubectl logs traffic-test
echo "All service requests succeeded during the rollout."
kubectl delete pod traffic-test --ignore-not-found
