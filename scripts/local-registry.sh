#!/usr/bin/env bash
# Build container images and load into kind/k3d local registry.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="${REGISTRY:-localhost:5000}"
CLUSTER_NAME="${CLUSTER_NAME:-gitops-sample}"

build_and_load() {
  local app=$1
  local dir="$REPO_ROOT/apps/$app"
  if [[ ! -d "$dir" ]]; then
    echo "App dir not found: $dir"
    return 1
  fi
  echo "Building $app..."
  docker build -t "$app:latest" "$dir"
  echo "Tagging for registry: $REGISTRY/$app:latest"
  docker tag "$app:latest" "$REGISTRY/$app:latest"
  echo "Loading into kind/k3d..."
  kind load docker-image "$app:latest" --name "$CLUSTER_NAME" 2>/dev/null || \
  k3d image import "$app:latest" -c "$CLUSTER_NAME" 2>/dev/null || \
  echo "Could not load into cluster; push to $REGISTRY manually if using external registry"
}

case "${1:-build}" in
  build)
    build_and_load orders-api
    build_and_load orders-web
    build_and_load worker
    echo "Done. Images: orders-api:latest, orders-web:latest, worker:latest"
    ;;
  *)
    echo "Usage: $0 build"
    exit 1
    ;;
esac
