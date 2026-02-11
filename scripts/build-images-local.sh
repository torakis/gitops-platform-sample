#!/usr/bin/env bash
# Build container images and load into k3d cluster (no registry required).
# Images: orders-api:latest, orders-web:latest, worker:latest
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-gitops-sample}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

build_and_load() {
  local app=$1
  local dir="$REPO_ROOT/apps/$app"
  if [[ ! -d "$dir" ]]; then
    echo "App dir not found: $dir"
    return 1
  fi
  echo "=== Building $app ==="
  docker build -t "$app:latest" "$dir"
  echo "=== Loading $app into k3d cluster $CLUSTER_NAME ==="
  k3d image import "$app:latest" -c "$CLUSTER_NAME"
}

build_and_load orders-api
build_and_load orders-web
build_and_load worker

echo ""
echo "=== Images loaded ==="
echo "orders-api:latest, orders-web:latest, worker:latest"
echo "Argo CD will use these when syncing apps-dev."
