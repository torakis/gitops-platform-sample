#!/usr/bin/env bash
# Create k3d cluster named gitops-sample with port mapping for ingress.
# Uses k3d's built-in Traefik; no nginx required. Use deploy/overlays/dev-k3d.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-gitops-sample}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Creating k3d cluster: $CLUSTER_NAME ==="
k3d cluster create "$CLUSTER_NAME" \
  -p "80:80@loadbalancer" \
  -p "443:443@loadbalancer" \
  --agents 1

echo "=== Creating namespaces (dev, staging, prod) ==="
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "=== k3d cluster ready ==="
echo "Cluster: $CLUSTER_NAME"
echo "Next: ./scripts/argocd-install.sh"
