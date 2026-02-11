#!/usr/bin/env bash
# Apply dev overlay (in-cluster postgres, dev.local)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NAMESPACE="${NAMESPACE:-dev}"

echo "=== Creating namespace $NAMESPACE ==="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "=== Applying dev overlay ==="
kubectl apply -k "$REPO_ROOT/deploy/overlays/dev"

echo ""
echo "=== Add to /etc/hosts: 127.0.0.1 dev.local ==="
echo "=== Watch pods: kubectl get pods -n $NAMESPACE -w ==="
