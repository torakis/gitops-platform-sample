# Lab 3: GitOps Basics

Change desired state in Git; Argo CD syncs the cluster.

## Goal

- Edit a manifest in Git
- See Argo CD detect the diff and sync (or sync manually)
- Verify the cluster matches Git

## Prerequisites

- kind/k3d cluster
- Argo CD installed (`argocd/scripts/install-argocd-kind.sh`)
- `apps-dev` Application pointing at `deploy/overlays/dev`
- Images built and loaded (`./scripts/local-registry.sh build`)

## Steps

### 1. Initial sync

Ensure the app is deployed:

```bash
kubectl apply -k deploy/overlays/dev
# Or let Argo sync:
# argocd app sync apps-dev
```

### 2. Change desired state in Git

Edit `deploy/overlays/dev/kustomization.yaml` and add a replica patch for orders-api:

```yaml
# Add this patch (before commonLabels if present)
- target:
    kind: Deployment
    name: orders-api
  patch: |-
    - op: replace
      path: /spec/replicas
      value: 2
```

### 3. Commit and push (or apply locally)

```bash
git add deploy/overlays/dev/kustomization.yaml
git commit -m "chore: scale orders-api to 2 replicas in dev"
git push
```

### 4. Argo CD sync

**If auto-sync is enabled**: Argo CD will detect the diff within a few minutes and sync automatically.

**Manual sync**:

```bash
argocd app sync apps-dev
```

Or use the Argo CD UI: `kubectl port-forward svc/argocd-server -n argocd 8080:443` → https://localhost:8080

### 5. Verify

```bash
kubectl get pods -n dev -l app=orders-api
```

**Expected output**:

```
NAME                          READY   STATUS    RESTARTS   AGE
orders-api-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
orders-api-xxxxxxxxxx-yyyyy    1/1     Running   0          30s
```

Two `orders-api` pods.

### 6. Rollback

Revert the patch and push. Argo CD will reconcile back to 1 replica.

---

## Why It Happened

- **Git as source of truth**: Argo CD continuously compares cluster state to the manifests in Git. Any diff triggers sync (if automated) or shows "OutOfSync."
- **Declarative**: You describe *what* you want (2 replicas), not *how* to get there.

## How to Prevent Issues in a Platform

- **Enforce Git-only changes**: Disable `kubectl` for app teams or restrict to read-only; all changes via PRs.
- **CI checks**: Validate manifests before merge (e.g. `kubectl apply --dry-run`, Kustomize build).
- **Argo CD sync policy**: Use `selfHeal: true` and `prune: true` for dev/staging; prod often uses manual sync.
