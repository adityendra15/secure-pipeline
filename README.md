# Automated Secure Website Deployment Pipeline

[![Automated Secure Website Deployment Pipeline](https://github.com/adityendra15/secure-pipeline/actions/workflows/pipeline.yml/badge.svg)](https://github.com/adityendra15/secure-pipeline/actions/workflows/pipeline.yml)

A deliberately small beginner project that demonstrates a complete secure CI/CD flow:

```text
Git push
  -> build Docker image
  -> test container
  -> scan image with Trivy
  -> generate an SBOM
  -> push image to GitHub Container Registry
  -> create a temporary kind Kubernetes cluster
  -> deploy the application
  -> verify the rollout and health endpoint
```

The website is intentionally tiny. The main learning goal is the pipeline, container security, and Kubernetes deployment.

## What the website does

- `GET /` returns `Secure Pipeline Application is Running`.
- `GET /healthz` returns `OK` with HTTP status 200.
- Any other path returns `Not Found` with HTTP status 404.

## Folder structure

```text
secure-pipeline/
├── .github/workflows/pipeline.yml
├── k8s/deployment.yaml
├── k8s/service.yaml
├── .dockerignore
├── .gitignore
├── app.py
├── Dockerfile
└── README.md
```

## Run the Python application directly

```bash
python3 app.py
```

Open `http://localhost:8080` in your browser.

Stop it by pressing `Control + C` in the terminal.

## Run it with Docker

Build the image:

```bash
docker build -t secure-pipeline-app:local .
```

Run the container:

```bash
docker run --rm -p 8080:8080 secure-pipeline-app:local
```

Open `http://localhost:8080` and `http://localhost:8080/healthz`.

## Scan the image locally with Trivy

This uses Trivy's official container image, so a separate Trivy installation is not required.

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.72.0 image \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 0 \
  secure-pipeline-app:local
```

This project reports vulnerabilities but does not block the pipeline. Blocking security gates belong to Project 2.

## Generate an SBOM locally

```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PWD:/workspace" \
  aquasec/trivy:0.72.0 image \
  --format cyclonedx \
  --output /workspace/sbom.cdx.json \
  secure-pipeline-app:local
```

The generated file is `sbom.cdx.json`.

## Deploy locally to Kubernetes with kind

Create a cluster:

```bash
kind create cluster --name secure-pipeline
```

Load the local image into the cluster:

```bash
kind load docker-image secure-pipeline-app:local --name secure-pipeline
```

Apply the Kubernetes files:

```bash
kubectl apply -f k8s/
```

Wait for the rollout:

```bash
kubectl rollout status deployment/secure-pipeline
```

See the resources:

```bash
kubectl get deployments,pods,services
```

Access the application:

```bash
kubectl port-forward service/secure-pipeline-service 8080:80
```

Open `http://localhost:8080`.

Delete the practice cluster when finished:

```bash
kind delete cluster --name secure-pipeline
```

## Use the GitHub Actions pipeline

1. Fork or clone this repository.
2. Commit and push a code change, or use the manual workflow trigger.
3. Open the repository's **Actions** tab.
4. Open the workflow named **Automated Secure Website Deployment Pipeline**.

No custom secret is required. GitHub supplies `GITHUB_TOKEN`, and the workflow grants it permission to push the image to GitHub Container Registry.

The workflow deploys to a fresh temporary `kind` cluster inside the GitHub-hosted runner. This proves automated Kubernetes deployment, but it is not permanent public hosting. The cluster is destroyed when the workflow runner finishes.

## Why two replicas and two probes are used

- Two replicas mean Kubernetes tries to keep two copies of the application running.
- The readiness probe prevents an unready copy from receiving traffic.
- The liveness probe asks whether a running copy is still healthy and allows Kubernetes to restart it if needed.
- `maxUnavailable: 0` tells Kubernetes not to intentionally remove an available replica during a rolling update.
- `maxSurge: 1` allows one extra replica to start during that update.

Together, these settings demonstrate self-healing and a rolling-update configuration designed to avoid downtime during a normal rollout.

## Honest project boundary

This is a learning and interview demonstration project, not a production cloud platform. It genuinely builds, tests, scans, generates an SBOM, pushes an image, deploys to Kubernetes, and verifies the rollout. Production systems would additionally use a long-lived cluster, protected environments, signed images, stronger policy gates, monitoring, and secret management.
