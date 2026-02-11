#!/usr/bin/env bash
# Install Argo CD on AKS using Helm
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARGOCD_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Adding Argo Helm repo ==="
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "=== Creating argocd namespace ==="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "=== Installing Argo CD (AKS overrides) ==="
helm upgrade --install argocd argo/argo-cd -n argocd \
  -f "$ARGOCD_DIR/install/values.yaml" \
  -f "$ARGOCD_DIR/install/values-aks.yaml"

echo "=== Waiting for Argo CD server ==="
kubectl wait -n argocd --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=120s

echo ""
echo "=== Argo CD ready ==="
echo "  Get credentials: az aks get-credentials -g <rg> -n <cluster>"
echo "  Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "  LoadBalancer: kubectl get svc -n argocd argocd-server"
echo ""
