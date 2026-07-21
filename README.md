# Automated Secure Website Deployment Pipeline

This deliberately small project implements the resume claims:

- A push to `main` automatically runs GitHub Actions.
- Tests run and a Docker image is built.
- Trivy blocks images with fixable critical CVEs.
- A CycloneDX SBOM is generated and retained as an artifact.
- The image is pushed to GitHub Container Registry with an immutable commit-SHA tag.
- A Kind Kubernetes cluster is created and the image is deployed automatically.
- Readiness and liveness probes validate application health.
- The workflow verifies rollout completion.
- It deletes a Pod and proves Kubernetes restores two replicas.
- It performs a rolling update while sending continuous requests and fails if any request is unavailable.

## Architecture

```text
Git push
  -> GitHub Actions
  -> Python tests
  -> Docker build
  -> Trivy CVE gate
  -> CycloneDX SBOM
  -> GHCR push
  -> Kind Kubernetes deployment
  -> rollout and health validation
  -> self-healing and rolling-update tests
```

## Run locally

Requirements: Docker Desktop, Python 3, kubectl and Kind.

```bash
./scripts/local-demo.sh
```

In a second Terminal:

```bash
./scripts/demo-self-healing.sh
./scripts/demo-zero-downtime.sh
```

## GitHub setup

Create a public repository named `secure-pipeline`, push this folder to `main`, and enable GitHub Actions. The workflow uses GitHub's built-in `GITHUB_TOKEN`; you do not store a registry password.

## Accurate zero-downtime wording

The project demonstrates a rolling update configured with two replicas, `maxUnavailable: 0`, readiness probes, graceful termination, and continuous successful health requests. It does not claim that every imaginable infrastructure outage is impossible.
