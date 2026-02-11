#!/usr/bin/env bash
# Check that required tools are installed and usable.
set -euo pipefail

FAIL=0
check() {
  if command -v "$1" &>/dev/null; then
    echo "  OK  $1: $(command -v "$1")"
  else
    echo "  MISS $1"
    FAIL=1
  fi
}

echo "=== Required ==="
check docker
check kubectl
if command -v kind &>/dev/null || command -v k3d &>/dev/null; then
  echo "  OK  kind or k3d"
else
  echo "  MISS kind or k3d (need one)"
  FAIL=1
fi
echo ""
echo "=== Optional (for full workflow) ==="
check helm
check k3d
check terraform
check argocd
check dotnet
check node
echo ""

if [[ $FAIL -eq 1 ]]; then
  echo "Some required tools are missing. Install:"
  echo "  - Docker: https://docs.docker.com/get-docker/"
  echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
  echo "  - kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
  echo ""
  echo "Optional: helm, k3d, terraform, argocd CLI, .NET 8, Node.js 20+"
  exit 1
fi

echo "All required tools present."
