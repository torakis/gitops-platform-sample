#!/usr/bin/env bash
# Install Argo CD on kind using Helm
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARGOCD_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Adding Argo Helm repo ==="
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "=== Creating argocd namespace ==="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "=== Installing Argo CD (kind overrides) ==="
helm upgrade --install argocd argo/argo-cd -n argocd \
  -f "$ARGOCD_DIR/install/values.yaml" \
  -f "$ARGOCD_DIR/install/values-kind.yaml"

echo "=== Waiting for Argo CD server ==="
kubectl wait -n argocd --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=120s

echo ""
echo "=== Argo CD ready ==="
echo "  Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "  Port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  UI: https://localhost:8080"
echo ""
echo "=== Bootstrap app-of-apps ==="
echo "  1. Set REPO_URL in argocd/applications/root-app.yaml"
echo "  2. kubectl apply -f $ARGOCD_DIR/projects/ -n argocd"
echo "  3. kubectl apply -f $ARGOCD_DIR/applications/root-app.yaml -n argocd"
echo ""
