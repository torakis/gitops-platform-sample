#!/usr/bin/env bash
# Optional: Rebuild image, bump tag in manifest, commit. Triggers Argo sync if watching.
# Usage: ./scripts/dev-loop.sh orders-api   (default app)
# Or:    ./scripts/dev-loop.sh orders-web
set -euo pipefail

APP="${1:-orders-api}"
CLUSTER_NAME="${CLUSTER_NAME:-gitops-sample}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Dev loop: $APP ==="
echo "1. Building $APP..."
docker build -t "$APP:latest" "$REPO_ROOT/apps/$APP"
echo "2. Loading into k3d..."
k3d image import "$APP:latest" -c "$CLUSTER_NAME"

# Optionally update image tag in deploy and commit (for Argo Git sync)
# Uncomment below if you want to bump tag on each build:
# TAG="dev-$(date +%Y%m%d%H%M)"
# kubectl set image deployment/$APP api=$APP:$TAG -n dev  # Argo will revert to Git state
# For GitOps: patch deploy/base/$APP or overlay, commit, push. Argo syncs.
echo ""
echo "Done. Image loaded as $APP:latest."
echo "To trigger rollback/restart: kubectl rollout restart deployment/$APP -n dev"
echo "For GitOps: update image tag in deploy/, commit, push. Argo will sync."
