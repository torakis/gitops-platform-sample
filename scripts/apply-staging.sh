#!/usr/bin/env bash
# Apply staging overlay (external DB required)
# PREREQUISITE: Create orders-db-secret with managed DB connection string
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NAMESPACE="${NAMESPACE:-staging}"

echo "=== Ensure orders-db-secret exists ==="
if ! kubectl get secret orders-db-secret -n "$NAMESPACE" &>/dev/null; then
  echo "ERROR: Create orders-db-secret first:"
  echo "  kubectl create secret generic orders-db-secret \\"
  echo "    --from-literal=connection-string='Host=YOUR_DB;Port=5432;Database=orders;...' \\"
  echo "    -n $NAMESPACE"
  exit 1
fi

echo "=== Creating namespace $NAMESPACE ==="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "=== Applying staging overlay ==="
kubectl apply -k "$REPO_ROOT/deploy/overlays/staging"
