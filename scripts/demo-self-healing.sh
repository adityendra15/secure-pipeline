#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-secure-pipeline}"
DEPLOYMENT="secure-pipeline-app"
LABEL="app=secure-pipeline"

kubectl rollout status deployment/${DEPLOYMENT} \
  --namespace "${NAMESPACE}" \
  --timeout=120s

DELETED_POD="$(kubectl get pods \
  --namespace "${NAMESPACE}" \
  --selector "${LABEL}" \
  --sort-by=.metadata.creationTimestamp \
  --output jsonpath='{.items[0].metadata.name}')"

DELETED_UID="$(kubectl get pod "${DELETED_POD}" \
  --namespace "${NAMESPACE}" \
  --output jsonpath='{.metadata.uid}')"

echo "Deleting pod ${DELETED_POD} (${DELETED_UID}) to simulate a failure."
kubectl delete pod "${DELETED_POD}" --namespace "${NAMESPACE}" --wait=true --timeout=120s

kubectl rollout status deployment/${DEPLOYMENT} \
  --namespace "${NAMESPACE}" \
  --timeout=180s

READY_REPLICAS="$(kubectl get deployment "${DEPLOYMENT}" \
  --namespace "${NAMESPACE}" \
  --output jsonpath='{.status.readyReplicas}')"

if [[ "${READY_REPLICAS}" != "2" ]]; then
  echo "Self-healing check failed: expected 2 ready replicas, found ${READY_REPLICAS:-0}." >&2
  exit 1
fi

if kubectl get pods \
  --namespace "${NAMESPACE}" \
  --selector "${LABEL}" \
  --output jsonpath='{range .items[*]}{.metadata.uid}{"\n"}{end}' | grep --quiet --fixed-strings "${DELETED_UID}"; then
  echo "Self-healing check failed: the deleted pod UID is still present." >&2
  exit 1
fi

echo "Self-healing verified: Kubernetes replaced the deleted pod and restored 2 ready replicas."
