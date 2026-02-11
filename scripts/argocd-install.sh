#!/usr/bin/env bash
# Install Argo CD via Helm for k3d/kind.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARGOCD_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/argocd"

echo "=== Adding Argo Helm repo ==="
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "=== Creating argocd namespace ==="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "=== Installing Argo CD (k3d/kind overrides: NodePort, insecure) ==="
helm upgrade --install argocd argo/argo-cd -n argocd \
  -f "$ARGOCD_DIR/install/values.yaml" \
  -f "$ARGOCD_DIR/install/values-kind.yaml"

echo "=== Waiting for Argo CD server ==="
kubectl wait -n argocd --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=180s

echo ""
echo "=== Argo CD ready ==="
echo "Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "Port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "UI: https://localhost:8080 (accept self-signed cert)"
echo ""
echo "Next: ./scripts/bootstrap.sh (Argo apps) or see docs/local-deploy-gitops.md"
