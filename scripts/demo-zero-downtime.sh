#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-secure-pipeline}"
DEPLOYMENT="secure-pipeline-app"
TRAFFIC_POD="traffic-check"
SERVICE_URL="http://secure-pipeline-service/health/ready"
REQUEST_COUNT="${REQUEST_COUNT:-40}"
NEW_VERSION="${NEW_VERSION:-rollout-$(date +%s)}"
LOG_FILE="${LOG_FILE:-traffic-check.log}"

cleanup() {
  kubectl delete pod "${TRAFFIC_POD}" --namespace "${NAMESPACE}" --ignore-not-found=true >/dev/null 2>&1 || true
}
trap cleanup EXIT

cleanup
kubectl run "${TRAFFIC_POD}" \
  --namespace "${NAMESPACE}" \
  --image=curlimages/curl:8.12.1 \
  --restart=Never \
  --command -- sh -c 'sleep 600'

kubectl wait pod/${TRAFFIC_POD} \
  --namespace "${NAMESPACE}" \
  --for=condition=Ready \
  --timeout=120s

kubectl exec "${TRAFFIC_POD}" --namespace "${NAMESPACE}" -- sh -c "
  i=1
  while [ \"\${i}\" -le '${REQUEST_COUNT}' ]; do
    code=\$(curl --silent --show-error --output /dev/null --write-out '%{http_code}' '${SERVICE_URL}' || true)
    echo \"request=\${i} status=\${code}\"
    if [ \"\${code}\" != '200' ]; then
      exit 1
    fi
    i=\$((i + 1))
    sleep 1
  done
" >"${LOG_FILE}" 2>&1 &
TRAFFIC_PID=$!

sleep 2
echo "Triggering rolling update by changing APP_VERSION to ${NEW_VERSION}."
kubectl set env deployment/${DEPLOYMENT} \
  --namespace "${NAMESPACE}" \
  APP_VERSION="${NEW_VERSION}"

kubectl rollout status deployment/${DEPLOYMENT} \
  --namespace "${NAMESPACE}" \
  --timeout=180s

if ! wait "${TRAFFIC_PID}"; then
  cat "${LOG_FILE}" >&2
  echo "Zero-downtime check failed: at least one request did not return HTTP 200." >&2
  exit 1
fi

cat "${LOG_FILE}"
echo "Zero-downtime check passed: all ${REQUEST_COUNT} requests returned HTTP 200 during the rolling update."
