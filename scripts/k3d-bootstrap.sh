#!/usr/bin/env bash
# Bootstrap a k3d cluster with Argo CD and ingress for local GitOps development.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-gitops-sample}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Creating k3d cluster: $CLUSTER_NAME ==="
k3d cluster create "$CLUSTER_NAME" \
  -p "80:80@loadbalancer" \
  -p "443:443@loadbalancer" \
  --agents 2

echo "=== Installing Argo CD ==="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --namespace argocd --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=120s

echo "=== Note: k3d uses Traefik by default. For nginx ingress, run: ==="
echo "  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml"
echo "=== Or change deploy/overlays/*/ingress.yaml to use ingressClassName: traefik ==="
echo ""
echo "=== Creating namespaces ==="
for ns in dev staging prod; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

echo ""
echo "=== Bootstrap complete ==="
echo "Cluster: $CLUSTER_NAME"
echo ""
echo "Argo CD:"
echo "  Get admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo "  Port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
