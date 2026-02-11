#!/usr/bin/env bash
# Port-forward helpers for local development. Run in separate terminals.
# Default: use dev.local + /etc/hosts. Use this script if ingress is not reachable.
set -euo pipefail

echo "=== Port-forward commands (run in separate terminals) ==="
echo ""
echo "# 1. Argo CD UI"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  -> https://localhost:8080  (admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo ""
echo "# 2. Orders web (if dev.local not working)"
echo "kubectl port-forward svc/orders-web -n dev 3000:80"
echo "  -> http://localhost:3000"
echo ""
echo "# 3. Orders API (Swagger, health)"
echo "kubectl port-forward svc/orders-api -n dev 5000:5000"
echo "  -> http://localhost:5000  (Swagger: /swagger, health: /healthz)"
echo ""

# Optional: start Argo CD port-forward in background
if [[ "${1:-}" == "--background" ]]; then
  echo "Starting Argo CD port-forward in background..."
  kubectl port-forward svc/argocd-server -n argocd 8080:443 &
  echo "PID: $!. Stop with: kill $!"
fi
