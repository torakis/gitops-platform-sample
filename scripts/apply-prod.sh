#!/usr/bin/env bash
# Apply prod overlay (external DB, HPA, PDB)
# PREREQUISITE: Create orders-db-secret with managed DB connection string
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NAMESPACE="${NAMESPACE:-prod}"

echo "=== Ensure orders-db-secret exists ==="
if ! kubectl get secret orders-db-secret -n "$NAMESPACE" &>/dev/null; then
  echo "ERROR: Create orders-db-secret first (see apply-staging.sh)"
  exit 1
fi

echo "=== Creating namespace $NAMESPACE ==="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "=== Applying prod overlay ==="
kubectl apply -k "$REPO_ROOT/deploy/overlays/prod"
