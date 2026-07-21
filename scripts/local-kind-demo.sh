#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-secure-pipeline}"
IMAGE="${IMAGE:-secure-pipeline-app:local}"
VERSION="${VERSION:-local}"

command -v docker >/dev/null || { echo "Docker is required." >&2; exit 1; }
command -v kind >/dev/null || { echo "kind is required." >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required." >&2; exit 1; }

docker build --tag "${IMAGE}" .

if ! kind get clusters | grep --quiet --exact-match "${CLUSTER_NAME}"; then
  kind create cluster --name "${CLUSTER_NAME}" --config kind-config.yaml
fi

kind load docker-image "${IMAGE}" --name "${CLUSTER_NAME}"
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/service.yaml
bash scripts/render-manifest.sh "${IMAGE}" "${VERSION}" | kubectl apply -f -
kubectl rollout status deployment/secure-pipeline-app --namespace secure-pipeline --timeout=180s
bash scripts/smoke-test.sh
bash scripts/demo-self-healing.sh
bash scripts/demo-zero-downtime.sh
