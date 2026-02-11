# Lab 2: GitOps Flow

Understand how GitOps works: Git as source of truth, Argo CD sync.

## Concepts

- **Declarative**: Desired state in Git (manifests)
- **Automated**: Argo CD reconciles cluster to match Git
- **Auditable**: All changes via Git history

## Steps

### 1. Change a manifest

Edit `deploy/overlays/dev/kustomization.yaml` and add a replica patch:

```yaml
replicas:
- name: orders-api
  count: 2
```

### 2. Apply (without Argo CD)

```bash
kubectl apply -k deploy/overlays/dev
kubectl get pods -n dev -l app=orders-api
```

You should see 2 replicas.

### 3. With Argo CD

If Argo CD is managing the app:

- Commit and push the change
- Argo CD will detect the diff and sync (if auto-sync is on)
- Or sync manually from the UI or: `argocd app sync applications-dev`

### 4. Observe

- Argo CD UI shows "OutOfSync" → "Synced"
- `kubectl get pods -n dev` shows the new replica

## Rollback

Revert the Git commit and push. Argo CD will roll back the cluster.

## Diagram

```
     Developer                Git                    Argo CD              Kubernetes
         │                     │                         │                      │
         │  git push           │                         │                      │
         │────────────────────>│                         │                      │
         │                     │  poll / webhook         │                      │
         │                     │<────────────────────────│                      │
         │                     │                         │  kubectl apply       │
         │                     │                         │─────────────────────>│
         │                     │                         │                      │
```
