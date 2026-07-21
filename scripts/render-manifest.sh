#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:?Usage: scripts/render-manifest.sh <image> [version]}"
VERSION="${2:-manual}"

sed \
  -e "s|IMAGE_PLACEHOLDER|${IMAGE}|g" \
  -e "s|INITIAL_VERSION_PLACEHOLDER|${VERSION}|g" \
  kubernetes/deployment.yaml
