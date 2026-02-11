#!/usr/bin/env bash
# Bootstrap a kind cluster with Argo CD and nginx ingress for local GitOps development.
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-gitops-sample}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Creating kind cluster: $CLUSTER_NAME ==="
kind create cluster --name "$CLUSTER_NAME" --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

echo "=== Installing nginx ingress ==="
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod -l app.kubernetes.io/component=controller --timeout=90s

echo "=== Installing Argo CD (use argocd/scripts/install-argocd-kind.sh for Helm) ==="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --namespace argocd --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=120s

echo "=== Patching Argo CD server to NodePort ==="
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}' || true

echo "=== Creating namespaces (dev, staging, prod) ==="
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
echo "  Then open https://localhost:8080 (accept self-signed cert)"
echo ""
echo "To deploy apps:"
echo "  1. Build and load: ./scripts/local-registry.sh build"
echo "  2. Bootstrap Argo CD: ./argocd/scripts/install-argocd-kind.sh"
echo "  3. Apply root app: kubectl apply -f argocd/applications/root-app.yaml -n argocd"
echo "  Or without Argo: kubectl apply -k deploy/overlays/dev"
echo ""
