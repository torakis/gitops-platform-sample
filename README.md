# gitops-platform-sample

A hands-on learning mono-repo for **GitOps**, **Argo CD**, **Terraform**, **Platform Engineering**, and **Kubernetes administration (CKA)**.

**Local**: k3d cluster `gitops-sample`, no cloud account required.

---

## Prerequisites

- Docker Desktop
- kubectl
- k3d (`brew install k3d` or [k3d.io](https://k3d.io))
- .NET 8 SDK and Node.js 20+ (to build images; or use pre-built)
- Path A only: Git repo pushed to GitHub (for Argo sync)

---

## Run and Deploy

### Path A: With Argo CD (GitOps)

| Step | Action | Command |
|------|--------|---------|
| 1 | Verify tools | `./scripts/check-prereqs.sh` |
| 2 | Create cluster | `./scripts/k3d-up.sh` |
| 3 | Install Argo CD | `./scripts/argocd-install.sh` |
| 4 | Set your repo URL | `sed -i.bak 's|your-org|YOUR_GITHUB_USER|g' argocd/applications/local-bootstrap.yaml` |
| 5 | Bootstrap Argo apps | `./scripts/bootstrap.sh` |
| 6 | Build and load images | `./scripts/build-images-local.sh` |
| 7 | Add hosts entry | `echo '127.0.0.1 dev.local argo.dev.local' | sudo tee -a /etc/hosts` |
| 8 | Wait for sync (~2 min), verify | `kubectl get pods -n dev` |

### Path B: Without Argo CD (Manual)

| Step | Action | Command |
|------|--------|---------|
| 1 | Verify tools | `./scripts/check-prereqs.sh` |
| 2 | Create cluster | `./scripts/k3d-up.sh` |
| 3 | Build and load images | `./scripts/build-images-local.sh` |
| 4 | Deploy dev overlay | `./scripts/apply-dev-k3d.sh` |
| 5 | Add hosts entry | `echo '127.0.0.1 dev.local' | sudo tee -a /etc/hosts` |
| 6 | Verify | `kubectl get pods -n dev` |

### After Deploy

| Action | Command or URL |
|--------|----------------|
| Open app | http://dev.local |
| Argo CD UI (Path A only) | http://argo.dev.local (no port-forward needed) |

---

## Verify Everything Works

| Check | Command | Expected |
|-------|---------|----------|
| Cluster | `kubectl get nodes` | 1+ nodes Ready |
| Pods | `kubectl get pods -n dev` | orders-api, orders-web, worker, postgres Running |
| Web | `curl -s -o /dev/null -w "%{http_code}" http://dev.local/` | 200 |
| API | `curl -s http://dev.local/api/orders` | JSON array |
| Argo CD | `argocd app list` (after port-forward) | apps-dev Synced, Healthy |

**Example output**:

```bash
$ kubectl get pods -n dev
NAME                          READY   STATUS    RESTARTS   AGE
orders-api-xxxxxxxxxx-xxxxx    1/1     Running   0          3m
orders-web-xxxxxxxxxx-xxxxx    1/1     Running   0          3m
worker-xxxxxxxxxx-xxxxx        1/1     Running   0          3m
postgres-0                     1/1     Running   0          4m
```

**URLs**:

| Endpoint | URL |
|----------|-----|
| Orders web | http://dev.local |
| Orders API (via ingress) | http://dev.local/api |
| Argo CD UI | https://localhost:8080 (port-forward first) |
| API Swagger | http://localhost:5000/swagger (port-forward `svc/orders-api`) |

---

## Optional: Azure AKS Path

```bash
cd terraform/live/dev
cp dev.tfvars.example dev.tfvars
# Edit dev.tfvars: set acr_name (globally unique, alphanumeric only)
terraform init
terraform apply -var-file=dev.tfvars -auto-approve

az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw cluster_name)
# Install Argo CD, push images to ACR, update overlay image refs
```

Requires: `az login`, Azure subscription.

---

## Learning Roadmap

| Week | Focus | Actions |
|------|-------|---------|
| **Week 1** | Local cluster + GitOps | Run Quick Start. [docs/local-deploy-gitops.md](docs/local-deploy-gitops.md) (drift, prune). [Labs 1–4](docs/labs/). |
| **Week 2** | Debugging + platform | [Labs 5–9](docs/labs/): ImagePullBackOff, Service selector, DNS, RBAC, NetworkPolicy. [platform/](platform/). |
| **Week 3** | HPA, rollouts, Terraform | [Labs 10–12](docs/labs/). [Golden path](platform/standards/golden-path.md). Optional AKS Terraform. |

---

## Documentation

| Doc | Purpose |
|-----|---------|
| [how-it-works.md](docs/how-it-works.md) | Repo modules, GitOps flow, architecture |
| [local-deploy-gitops.md](docs/local-deploy-gitops.md) | End-to-end Argo CD: bootstrap, sync, drift, prune |
| [local-dev.md](docs/local-dev.md) | Run API + web locally, postgres in cluster |
| [troubleshooting-local.md](docs/troubleshooting-local.md) | Image pull, ingress, port-forward, RBAC, DNS |
| [verification.md](docs/verification.md) | Commands that should succeed, known limitations |
| [Labs](docs/labs/) | Step-by-step exercises |
| [Runbooks](docs/runbooks/) | Incident response, broken pod, DNS |

---

## Scripts

| Script | Purpose |
|--------|---------|
| `k3d-up.sh` | Create k3d cluster `gitops-sample` |
| `argocd-install.sh` | Install Argo CD via Helm |
| `bootstrap.sh` | Apply Argo CD local-bootstrap (platform-bootstrap + apps-dev) |
| `build-images-local.sh` | Build and load images into k3d (no registry) |
| `apply-dev-k3d.sh` | Apply dev-k3d overlay (no Argo CD) |
| `port-forward.sh` | Print port-forward commands |
| `dev-loop.sh` | Optional: rebuild image, load, restart |

---

## Make Targets

```bash
make local-k3d-up     # k3d cluster
make argocd-install  # Argo CD
make bootstrap       # Build + load images
make bootstrap-argocd # Apply Argo bootstrap apps
make deploy-dev      # Apply dev-k3d (no Argo)
make logs            # Tail orders-api
make destroy         # Delete cluster
make check-prereqs   # Verify tools
make print-hosts     # /etc/hosts entry
```

---

## License

MIT
