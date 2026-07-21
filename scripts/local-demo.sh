#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="secure-pipeline-demo"
IMAGE="secure-pipeline:local"

echo "1/7 Building the Docker image..."
docker build -t "$IMAGE" .

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "Reusing existing Kind cluster: $CLUSTER_NAME"
else
  echo "2/7 Creating Kind Kubernetes cluster..."
  kind create cluster --name "$CLUSTER_NAME" --config kind-config.yaml
fi

echo "3/7 Loading image into Kind..."
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"

echo "4/7 Rendering Kubernetes deployment..."
sed \
  -e "s|IMAGE_PLACEHOLDER|$IMAGE|g" \
  -e "s|VERSION_PLACEHOLDER|local-demo|g" \
  kubernetes/deployment.yaml > rendered-deployment.yaml

echo "5/7 Deploying two replicas with health probes..."
kubectl apply -f rendered-deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl rollout status deployment/secure-pipeline --timeout=120s

echo "6/7 Showing the running resources..."
kubectl get deployment,pods,service -l app=secure-pipeline
kubectl get service secure-pipeline

echo "7/7 Starting local access at http://127.0.0.1:8080"
echo "Leave this Terminal open. Press Control+C when finished."
kubectl port-forward service/secure-pipeline 8080:80
