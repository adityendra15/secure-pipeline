# Resume Claim Map

This file connects each resume statement to the smallest real implementation in this project.

## Claim 1

> Built a fully automated CI/CD pipeline that, on every code push to GitHub, builds the application, creates a Docker image, and deploys it to Kubernetes with zero manual intervention.

Implemented by `.github/workflows/pipeline.yml`:

- `on: push` starts the workflow for every Git push.
- `docker build` creates the container image.
- The workflow creates a fresh `kind` Kubernetes cluster.
- `kubectl apply --filename k8s/` deploys the application.
- `kubectl rollout status` automatically checks whether the deployment succeeded.

Precise interview explanation:

> On each push, GitHub Actions builds and tests the image, runs the security steps, pushes the image to GHCR, creates a temporary kind cluster, deploys the Kubernetes manifests, and waits for the rollout to complete. It is fully automatic, although the demonstration cluster is temporary rather than a permanent production cluster.

## Claim 2

> Integrated container security into the build stage: automated vulnerability scanning and SBOM generation before the image is pushed to the registry.

Implemented by `.github/workflows/pipeline.yml`:

- The Trivy vulnerability scan runs after the image build.
- Trivy produces a CycloneDX file named `sbom.cdx.json`.
- The SBOM is saved as a GitHub Actions artifact.
- Registry login and `docker push` occur only after those two steps.

Precise interview explanation:

> The image is scanned and its software inventory is generated before the registry push. In Project 1, the scan is report-only so the pipeline remains easy to demonstrate. Project 2 adds blocking security gates.

## Claim 3

> Configured Kubernetes Deployments with liveness/readiness health probes to validate each rollout and ensure zero-downtime, self-healing deployments.

Implemented by `k8s/deployment.yaml`:

- `replicas: 2` asks Kubernetes to maintain two application Pods.
- The readiness probe checks `/healthz` before a Pod receives traffic.
- The liveness probe checks `/healthz` and can trigger a container restart.
- `maxUnavailable: 0` keeps all required replicas available during a normal rolling update.
- `maxSurge: 1` permits one temporary extra replica during the update.
- The workflow runs `kubectl rollout status` to validate the rollout.

Precise interview explanation:

> The Deployment uses two replicas, readiness and liveness probes, and a rolling-update strategy with zero planned unavailable replicas. This demonstrates self-healing and is designed to avoid downtime during normal rollouts. I would avoid claiming that a small demo can guarantee availability under every infrastructure failure.
