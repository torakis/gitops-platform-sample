# Local GitOps Deployment with Argo CD

End-to-end workflow: bring up cluster, install Argo CD, bootstrap apps, build images, sync, demonstrate drift/self-heal and prune.

## Tech Stack

- **Cluster**: k3d, name `gitops-sample`
- **Images**: Built locally, loaded via `k3d image import` (no registry)
- **Ingress**: k3d Traefik (default)
- **Overlay**: `deploy/overlays/dev-k3d`
- **Host**: `dev.local` (add to `/etc/hosts`). Fallback: port-forward.

---

## Step 1: Bring Up Cluster

```bash
./scripts/k3d-up.sh
```

**Expected output**:

```
=== Creating k3d cluster: gitops-sample ===
...
=== k3d cluster ready ===
Cluster: gitops-sample
Next: ./scripts/argocd-install.sh
```

**Verify**:

```bash
kubectl get nodes
# NAME                     STATUS   ROLES                  AGE   VERSION
# k3d-gitops-sample-server-0   Ready    control-plane,master   1m    v1.x
```

---

## Step 2: Install Argo CD

```bash
./scripts/argocd-install.sh
```

**Expected output**:

```
=== Argo CD ready ===
Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
Port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443
UI: https://localhost:8080
```

**Verify**:

```bash
kubectl get pods -n argocd
# NAME                                READY   STATUS    RESTARTS   AGE
# argocd-application-controller-0      1/1     Running   0          2m
# argocd-server-xxxxxxxxxx-xxxxx       1/1     Running   0          2m
```

---

## Step 3: Set Repo URL in Local Bootstrap

Update `argocd/applications/local-bootstrap.yaml` so Argo can pull manifests. Replace `your-org` with your GitHub username or org.

```bash
# Example: your fork is https://github.com/myuser/gitops-platform-sample
sed -i.bak 's|your-org|myuser|g' argocd/applications/local-bootstrap.yaml
```

Or edit manually: change `repoURL: https://github.com/your-org/gitops-platform-sample.git` to your repo.

**If repo is local only (no push)**: Argo CD requires a reachable Git URL. Push to GitHub (or run a local Git server) and use that URL.

---

## Step 4: Bootstrap App-of-Apps

```bash
./scripts/bootstrap.sh
```

**Expected output**:

```
=== Applying Argo CD projects ===
...
=== Applying local bootstrap (platform-bootstrap + apps-dev) ===
...
=== Bootstrap complete ===
```

**Verify**:

```bash
kubectl get applications -n argocd
# NAME                 SYNC STATUS   HEALTH STATUS
# platform-bootstrap   Synced       Healthy
# apps-dev             OutOfSync     (or Progressing)
```

---

## Step 5: Build and Load Images

```bash
./scripts/build-images-local.sh
```

**Expected output**:

```
=== Building orders-api ===
...
=== Loading orders-api into k3d cluster gitops-sample ===
...
=== Images loaded ===
orders-api:latest, orders-web:latest, worker:latest
```

---

## Step 6: Sync and Wait for Apps

Argo CD will auto-sync. To sync manually:

```bash
argocd app sync apps-dev
# Or: argocd app sync platform-bootstrap
```

If Argo CD CLI not installed:

```bash
kubectl patch application apps-dev -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

**Verify** (after ~2–3 min):

```bash
kubectl get pods -n dev
```

**Expected output**:

```
NAME                          READY   STATUS    RESTARTS   AGE
orders-api-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
orders-web-xxxxxxxxxx-xxxxx    1/1     Running   0          2m
worker-xxxxxxxxxx-xxxxx        1/1     Running   0          2m
postgres-0                     1/1     Running   0          3m
```

```bash
argocd app list
# Or: kubectl get applications -n argocd
```

**Expected**:

```
NAME                 SYNC STATUS   HEALTH STATUS
platform-bootstrap   Synced       Healthy
apps-dev             Synced       Healthy
```

---

## Step 7: Add Host and Test Endpoints

```bash
echo '127.0.0.1 dev.local' | sudo tee -a /etc/hosts
```

**Test**:

```bash
# Orders web
curl -s -o /dev/null -w "%{http_code}" http://dev.local/
# Expected: 200

# Orders API
curl -s http://dev.local/api/orders
# Expected: JSON array, e.g. []

# Health
curl -s http://dev.local/api/healthz
# Expected: "Healthy" or similar
```

**URLs**:

| Endpoint | URL |
|----------|-----|
| Orders web | http://dev.local |
| Orders API (via ingress) | http://dev.local/api |
| Argo CD UI | https://localhost:8080 (after `kubectl port-forward svc/argocd-server -n argocd 8080:443`) |
| API Swagger (port-forward) | http://localhost:5000/swagger (after `kubectl port-forward svc/orders-api -n dev 5000:5000`) |

---

## Step 8: Demonstrate Drift and Self-Heal

### 8a. Introduce drift

```bash
kubectl scale deployment orders-api -n dev --replicas=0
```

**Verify**:

```bash
kubectl get pods -n dev -l app=orders-api
# No pods (or terminating)
```

### 8b. Argo detects drift

```bash
argocd app get apps-dev
# Or in Argo CD UI: apps-dev shows OutOfSync
```

```bash
kubectl get application apps-dev -n argocd -o jsonpath='{.status.sync.status}'
# Expected: OutOfSync
```

### 8c. Self-heal restores replicas

With `selfHeal: true`, Argo will revert within the poll interval (~3 min). To force immediately:

```bash
argocd app sync apps-dev
```

**Verify**:

```bash
kubectl get pods -n dev -l app=orders-api
# NAME                          READY   STATUS    RESTARTS   AGE
# orders-api-xxxxxxxxxx-xxxxx    1/1     Running   0          30s
```

Replicas restored to 1 (Git state).

---

## Step 9: Demonstrate Prune

### 9a. Remove worker from Kustomize in Git

Edit `deploy/overlays/dev-k3d/kustomization.yaml`. Under `resources:`, remove the line `- ../../base/worker`:

```yaml
resources:
- ../../base/orders-api
- ../../base/orders-web
# - ../../base/worker   # REMOVED
- ../../base/postgres
- ../../base/rbac
- ../../base/networkpolicy
- ingress.yaml
```

### 9b. Commit and push

```bash
git add deploy/overlays/dev-k3d/kustomization.yaml
git commit -m "chore: remove worker from dev overlay"
git push
```

### 9c. Argo prunes worker

Argo syncs (auto or manual). With `prune: true`, it deletes resources that are no longer in Git.

```bash
argocd app sync apps-dev --prune
```

**Verify**:

```bash
kubectl get pods -n dev -l app=worker
# No resources found
```

Worker deployment and pods are removed.

### 9d. Restore worker (optional)

Add `- ../../base/worker` back to `kustomization.yaml`, commit, push. Argo syncs and recreates worker.

---

## Verify Everything Works

| Check | Command | Expected |
|-------|---------|----------|
| Cluster | `kubectl get nodes` | 1+ nodes Ready |
| Argo CD | `kubectl get pods -n argocd` | argocd-server, application-controller Running |
| Apps | `kubectl get pods -n dev` | orders-api, orders-web, postgres Running |
| Argo sync | `argocd app list` | apps-dev Synced, Healthy |
| Web | `curl -s -o /dev/null -w "%{http_code}" http://dev.local/` | 200 |
| API | `curl -s http://dev.local/api/orders` | JSON array |
| Argo UI | Open https://localhost:8080 (after port-forward) | Login, see apps |

---

## Fallback: Port-Forward

If `dev.local` does not work (e.g. ingress not reachable):

```bash
# Terminal 1: Argo CD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 2: Orders web
kubectl port-forward svc/orders-web -n dev 3000:80
# Open http://localhost:3000

# Terminal 3: Orders API (Swagger)
kubectl port-forward svc/orders-api -n dev 5000:5000
# Open http://localhost:5000/swagger
```
