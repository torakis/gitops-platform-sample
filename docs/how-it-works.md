# How It Works

Architecture and GitOps flows for gitops-platform-sample.

## Repo Modules

| Module | Path | Purpose |
|--------|------|---------|
| **Apps** | `apps/` | orders-api (.NET 8), orders-web (React), worker (.NET). Source code and Dockerfiles. |
| **Deploy** | `deploy/` | Kustomize bases and overlays. GitOps manifests; Argo CD syncs these. |
| **Platform** | `platform/` | Guardrails, observability, standards, environment definitions (namespaces). |
| **Argo CD** | `argocd/` | Helm install values, AppProjects, Application manifests (app-of-apps). |
| **Terraform** | `terraform/` | Azure AKS, ACR, networking (optional; not used for local). |
| **Scripts** | `scripts/` | k3d-up, argocd-install, bootstrap, build-images-local, port-forward. |

## GitOps Flow

```
┌──────────────┐     Git push      ┌──────────────┐     poll/webhook    ┌──────────────┐
│  Developer   │ ───────────────►  │  Git (repo)  │ ◄─────────────────  │   Argo CD    │
└──────────────┘                   └──────────────┘                     └──────┬───────┘
                                                                               │
                                    Manifests (Kustomize)                      │ kubectl apply
                                    deploy/overlays/dev-k3d                    │
                                                                               ▼
                                                                        ┌──────────────┐
                                                                        │ Kubernetes   │
                                                                        │ (k3d cluster)│
                                                                        └──────────────┘
```

1. **Source of truth**: Git. All desired state lives in `deploy/`, `platform/`, `argocd/`.
2. **Argo CD**: Compares cluster state to Git. Drift triggers sync (if automated).
3. **Reconciliation**: Argo applies manifests from Git to the cluster.

## App-of-Apps

For local k3d we use **local bootstrap** (not the full root app):

```
argocd/applications/local-bootstrap.yaml
├── platform-bootstrap  → platform/environments (namespaces)
└── apps-dev            → deploy/overlays/dev-k3d (orders-api, orders-web, worker, postgres)
```

The root app (`root-app.yaml`) is for full deployments (staging, prod, nginx). For local, we skip nginx and use k3d's Traefik.

## Data Flow

```
Host (dev.local)
       │
       ▼
k3d loadbalancer :80
       │
       ▼
Traefik (k3d built-in)
       │
       ├── /     → orders-web:80
       └── /api  → orders-api:5000
              │
              ▼
         postgres:5432
```

## Sync Policy

| App | prune | selfHeal |
|-----|-------|----------|
| platform-bootstrap | true | true |
| apps-dev | true | true |

- **prune**: Remove resources that exist in cluster but not in Git.
- **selfHeal**: Revert manual changes (e.g. `kubectl scale`) to match Git.

## Image Flow (Local)

1. `./scripts/build-images-local.sh` builds `orders-api:latest`, etc.
2. `k3d image import` loads images into cluster nodes (no registry).
3. Deployments reference `orders-api:latest`; kubelet pulls from local cache.
4. No push step; no cloud registry.

## Key Paths

| What | Path |
|------|------|
| Dev overlay (k3d) | `deploy/overlays/dev-k3d` |
| Dev overlay (kind/nginx) | `deploy/overlays/dev` |
| Orders API base | `deploy/base/orders-api/` |
| Argo local bootstrap | `argocd/applications/local-bootstrap.yaml` |
| Ingress (k3d) | `deploy/overlays/dev-k3d/ingress.yaml` |
