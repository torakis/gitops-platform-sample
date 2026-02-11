#!/usr/bin/env bash
# Bootstrap Argo CD app-of-apps for local k3d: apply projects + local apps.
# Uses local-bootstrap.yaml (platform-bootstrap + apps-dev with dev-k3d overlay).
# Prerequisite: Set repoURL in argocd/applications/local-bootstrap.yaml to your fork.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Applying Argo CD projects ==="
kubectl apply -f "$REPO_ROOT/argocd/projects/" -n argocd

echo "=== Applying local bootstrap (platform-bootstrap + apps-dev) ==="
# Replace repoURL for local/fork - example: sed -i.bak 's|your-org|myuser|g' ...
LOCAL_BOOTSTRAP="$REPO_ROOT/argocd/applications/local-bootstrap.yaml"
if grep -q "your-org" "$LOCAL_BOOTSTRAP" 2>/dev/null; then
  echo "ERROR: local-bootstrap.yaml has repoURL with 'your-org'. Update to your repo first:"
  echo "  sed -i.bak 's|your-org|YOUR_GITHUB_USER|g' argocd/applications/local-bootstrap.yaml"
  echo "Or set SKIP_REPO_CHECK=1 to continue anyway (Argo will fail to sync until repo is correct)."
  [[ "${SKIP_REPO_CHECK:-}" == "1" ]] || exit 1
fi

kubectl apply -f "$LOCAL_BOOTSTRAP" -n argocd

echo ""
echo "=== Bootstrap complete ==="
echo "Argo will sync platform-bootstrap (namespaces) and apps-dev (orders stack)."
echo "Build and load images first: ./scripts/build-images-local.sh"
echo "Then Argo syncs; or trigger: argocd app sync apps-dev"
