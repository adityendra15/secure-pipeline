#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-secure-pipeline}"
SERVICE_URL="http://secure-pipeline-service/health/ready"

kubectl run smoke-test \
  --namespace "${NAMESPACE}" \
  --image=curlimages/curl:8.12.1 \
  --restart=Never \
  --rm \
  --attach \
  --quiet \
  --command -- curl --fail --silent --show-error "${SERVICE_URL}"

echo "Smoke test passed: ${SERVICE_URL} returned HTTP 200."
