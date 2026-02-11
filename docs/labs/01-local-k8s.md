# Lab 1: Local Kubernetes

Get the full stack running on kind or k3d.

## Steps

### 1. Bootstrap the cluster

```bash
./scripts/kind-bootstrap.sh
```

Or with k3d:

```bash
./scripts/k3d-bootstrap.sh
```

### 2. Build and load images

```bash
./scripts/local-registry.sh build
```

This builds orders-api, orders-web, worker and loads them into the cluster.

### 3. Start PostgreSQL

Postgres is included in the dev overlay. We'll deploy everything together.

### 4. Create dev namespace (if not exists)

The bootstrap script creates dev, staging, prod. If needed:

```bash
kubectl create namespace dev
```

### 5. Deploy the dev overlay

```bash
kubectl apply -k deploy/overlays/dev
```

### 6. Verify

```bash
kubectl get pods -n dev
kubectl get svc -n dev
```

### 7. Access the app

Add to `/etc/hosts`:

```
127.0.0.1 dev.local
```

Run `./scripts/generate-local-hosts.sh` for the exact command. Then open: http://dev.local

### 8. Argo CD (optional)

If using Argo CD, get the admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Port-forward and open https://localhost:8080:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Architecture (ASCII)

```
                    ┌─────────────────┐
                    │   Ingress       │
                    │   (nginx)       │
                    └────────┬────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                 │
           ▼                 ▼                 │
    ┌──────────────┐  ┌──────────────┐        │
    │ orders-web   │  │ orders-api   │        │
    │ (port 80)    │  │ (port 5000)  │        │
    └──────────────┘  └──────┬───────┘        │
                             │                 │
                             │                 │
                             ▼                 ▼
                      ┌──────────────┐  ┌──────────────┐
                      │ postgres     │  │ worker       │
                      │ (port 5432)  │  │ (port 5001)  │
                      └──────────────┘  └──────────────┘
```
