# Argo CD GitOps Setup

This directory contains Argo CD installation (Helm), AppProjects, and Application manifests for the app-of-apps pattern.

## Structure

```
argocd/
├── install/           # Helm values for Argo CD
│   ├── values.yaml    # Base
│   ├── values-kind.yaml
│   └── values-aks.yaml
├── projects/          # AppProject boundaries
│   ├── platform-project.yaml
│   └── apps-project.yaml
├── applications/      # App-of-apps
│   ├── root-app.yaml      # Bootstrap point (apply manually)
│   ├── platform-app.yaml  # ingress-nginx, cert-manager (opt), prometheus (opt)
│   └── apps-app.yaml      # orders dev/staging/prod
└── README.md
```

## 1. Installing Argo CD

### Kind / k3d (local)

```bash
# Add Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create namespace
kubectl create namespace argocd

# Install with kind overrides (NodePort, insecure for local)
helm install argocd argo/argo-cd -n argocd \
  -f argocd/install/values.yaml \
  -f argocd/install/values-kind.yaml

# Wait for ready
kubectl wait -n argocd --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=120s

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo ""
```

### AKS

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

kubectl create namespace argocd

helm install argocd argo/argo-cd -n argocd \
  -f argocd/install/values.yaml \
  -f argocd/install/values-aks.yaml
```

## 2. Bootstrapping App-of-Apps

After Argo CD is running:

1. **Set your repo URL** in `argocd/applications/root-app.yaml`:
   ```bash
   # Concrete example: use your GitHub username or org
   sed -i.bak 's|your-org|my-github-username|g' argocd/applications/root-app.yaml
   # Or edit manually: change repoURL to https://github.com/my-github-username/gitops-platform-sample.git
   ```

2. **Apply projects** (optional; root uses `default` project):

   ```bash
   kubectl apply -f argocd/projects/ -n argocd
   ```

3. **Apply the root Application** (this is the single bootstrap point):

   ```bash
   kubectl apply -f argocd/applications/root-app.yaml -n argocd
   ```

4. The root app syncs `platform-app.yaml` and `apps-app.yaml`, which in turn deploy:
   - **platform-app**: ingress-nginx (and optionally cert-manager, prometheus)
   - **apps-app**: orders overlays (dev, staging, prod)

### Kind / k3d: Ingress conflict

The `scripts/kind-bootstrap.sh` installs ingress-nginx via static manifest. If you bootstrap Argo CD and sync the platform-app, you will have two ingress controllers.

**Options**:
1. **Skip platform-app on kind**: Apply only the apps (delete or don't sync `platform-ingress-nginx`).
2. **Use Argo CD for ingress**: Remove the ingress install from `kind-bootstrap.sh` and let the platform-app manage it.

## 3. Sync, Self-Heal, and Prune

| Setting | Meaning |
|---------|---------|
| **sync** | Argo CD applies the desired state from Git to the cluster |
| **selfHeal** | If the cluster drifts (someone edits a resource), Argo CD reverts it to match Git |
| **prune** | If a resource exists in the cluster but not in Git, Argo CD deletes it |

Configuration in Application manifests:

```yaml
syncPolicy:
  automated:
    prune: true      # Remove resources no longer in Git
    selfHeal: true   # Revert manual cluster changes
```

- **dev/staging**: `prune: true`, `selfHeal: true` (full automation)
- **prod**: `prune: false`, `selfHeal: false` (manual sync; safer for production)

## Kind vs AKS: Ingress

| Cluster | Ingress | Notes |
|---------|---------|------|
| **kind** | Often pre-installed by bootstrap | Skip platform-ingress-nginx or let it manage (may conflict) |
| **AKS** | platform-app installs via Helm | LoadBalancer; get external IP from `kubectl get svc -n ingress-nginx` |

## 4. Promotions: Dev → Staging → Prod

Promotions are **git-based**: you change which overlay (or image tag) is deployed by editing Git, then Argo CD syncs.

### Option A: Branch-based

- `main` → prod
- `staging` → staging
- `develop` → dev

Update each Application's `targetRevision` in `apps-app.yaml` to the branch.

### Option B: Path-based (recommended)

All environments use the same branch (`main`). Overlays differ by path:

- `deploy/overlays/dev`
- `deploy/overlays/staging`
- `deploy/overlays/prod`

To promote:

1. Update image tags in the overlay (e.g. `deploy/overlays/staging/kustomization.yaml` with new image tag).
2. Commit and push.
3. Argo CD syncs (auto for staging; manual for prod).

### Option C: Kustomize image tag promotion

```bash
# Promote v1.2.3 from staging to prod
kustomize edit set image orders-api=ghcr.io/org/repo/orders-api:v1.2.3
git add deploy/overlays/prod
git commit -m "Promote orders-api v1.2.3 to prod"
git push
```

Then sync the `apps-prod` Application (manually if prod has `selfHeal: false`).

## Port-Forward (local)

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
```

## CLI

```bash
argocd login localhost:8080
argocd app list
argocd app sync apps-dev
argocd app diff apps-prod
```
