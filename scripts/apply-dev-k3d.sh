#!/usr/bin/env bash
# Apply dev-k3d overlay (k3d + Traefik). Use when not using Argo CD.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Creating namespace dev ==="
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

echo "=== Applying dev-k3d overlay ==="
kubectl apply -k "$REPO_ROOT/deploy/overlays/dev-k3d"

echo ""
echo "=== Add to /etc/hosts: 127.0.0.1 dev.local ==="
echo "=== Watch: kubectl get pods -n dev -w ==="
