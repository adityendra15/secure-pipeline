# Automated Secure Website Deployment Pipeline

A small Flask application whose main purpose is to demonstrate a complete, automated build-scan-push-deploy workflow.

## What happens on every push to `main`

1. GitHub Actions installs dependencies and runs unit tests.
2. Docker builds an image tagged with the exact Git commit SHA.
3. Trivy creates a vulnerability report and a CycloneDX SBOM.
4. The reports are uploaded as GitHub Actions artifacts.
5. A blocking Trivy gate stops the workflow if fixable HIGH or CRITICAL vulnerabilities are found.
6. The approved immutable image is pushed to GitHub Container Registry (GHCR).
7. A temporary Kind Kubernetes cluster is created on the GitHub runner.
8. Kubernetes deploys two replicas using readiness, liveness and startup probes.
9. A smoke test calls the service inside the cluster.
10. One pod is deleted to verify self-healing.
11. Continuous requests run while a rolling update is triggered to verify availability during the controlled rollout.

## Important scope statement

The Kubernetes environment is an ephemeral Kind cluster created for CI demonstration and validation. It is not a permanent production cloud cluster. The zero-downtime check proves that all requests in this controlled test succeeded; it is not a universal guarantee against every possible failure.

## Project structure

```text
.
├── .github/workflows/pipeline.yml
├── kubernetes/
│   ├── deployment.yaml
│   ├── namespace.yaml
│   └── service.yaml
├── scripts/
│   ├── demo-self-healing.sh
│   ├── demo-zero-downtime.sh
│   ├── local-kind-demo.sh
│   ├── render-manifest.sh
│   └── smoke-test.sh
├── tests/test_app.py
├── app.py
├── Dockerfile
├── kind-config.yaml
├── requirements.txt
└── requirements-dev.txt
```

## Local application test

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
pytest
python app.py
```

Open `http://127.0.0.1:8080/` and `http://127.0.0.1:8080/health/ready`.

## Full local Kind demonstration

Install Docker, Kind and kubectl, then run:

```bash
scripts/local-kind-demo.sh
```

## Security and reliability choices

- Immutable commit-SHA image tags instead of `latest`
- Vulnerability scan and SBOM before registry push
- Non-root container user
- Read-only root filesystem
- Dropped Linux capabilities
- Disabled privilege escalation
- Resource requests and limits
- Two replicas
- Rolling update with `maxUnavailable: 0` and `maxSurge: 1`
- Startup, liveness and readiness probes
- Graceful pre-stop delay
