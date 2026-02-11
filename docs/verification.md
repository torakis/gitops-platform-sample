# Verification

Commands that should succeed, sanity checks, and known limitations.

## Commands That Should Succeed

After `make bootstrap` and `make deploy-dev` (or equivalent manual steps):

### Cluster connectivity

```bash
kubectl cluster-info
# Expected: Kubernetes control plane is running at https://...
```

```bash
kubectl get nodes
# Expected: nodes show Ready
```

### Namespaces

```bash
kubectl get namespaces
# Expected: dev, staging, prod exist
```

### Dev overlay

```bash
kubectl get pods -n dev
# Expected: orders-api, orders-web, worker, postgres pods in Running
```

```bash
kubectl get pods -n dev -o wide
# Expected: All READY 1/1 (or 2/2 for multi-container)
```

```bash
kubectl get svc -n dev
# Expected: orders-api, orders-web, worker, postgres, orders-ingress (if ingress creates svc)
```

```bash
kubectl get endpoints -n dev
# Expected: orders-api and orders-web show IP:port (not <none>)
```

### Application health

```bash
# From host (after adding dev.local to /etc/hosts)
curl -s http://dev.local/healthz 2>/dev/null || curl -s http://dev.local/
# Expected: 200 OK or HTML

curl -s -o /dev/null -w "%{http_code}" http://dev.local/api/orders
# Expected: 200 or 401 (depends on API)
```

### Argo CD (if installed)

```bash
kubectl get pods -n argocd
# Expected: argocd-server, argocd-application-controller Running
```

```bash
kubectl get applications -n argocd
# Expected: root or apps-dev (if applications applied)
```

---

## Sanity Checks

| Check | Command | Pass criterion |
|-------|---------|----------------|
| Pods Running | `kubectl get pods -n dev` | All pods Running, READY |
| No ImagePullBackOff | `kubectl get pods -n dev` | No ImagePullBackOff in STATUS |
| Endpoints present | `kubectl get endpoints -n dev` | orders-api, orders-web have IPs |
| Ingress responds | `curl -s -o /dev/null -w "%{http_code}" http://dev.local/` | 200 |
| Postgres ready | `kubectl exec -n dev postgres-0 -c postgres -- pg_isready -U postgres` | accepts connections |
| API health | `kubectl exec -n dev deploy/orders-api -- curl -s http://localhost:5000/healthz` | 200 or OK |

---

## Known Limitations

| Limitation | Details |
|------------|---------|
| **Ingress host** | Dev uses `dev.local`. Add `127.0.0.1 dev.local` to `/etc/hosts`. No wildcard DNS. |
| **kind** | Uses nginx ingress; kindnet does not support NetworkPolicy. Use Calico for NetworkPolicy labs. |
| **k3d** | Uses Traefik by default. Dev overlay expects `ingressClassName: nginx`. Either install nginx ingress or change overlay to `traefik`. |
| **Images** | Local: `orders-api:latest`, etc. Must be built and loaded (`make bootstrap` or `./scripts/local-registry.sh build`). |
| **Argo CD repo** | `argocd/applications/` references `https://github.com/your-org/gitops-platform-sample.git`. Set `REPO_URL` or use your fork. |
| **Staging/Prod** | Require `orders-db-secret` with external DB connection. Dev uses in-cluster postgres with default secret. |
| **Terraform** | AKS path requires Azure credentials (`az login`), unique `acr_name`. Backend is `local` by default. |
| **NetworkPolicy** | Lab 09 requires CNI with NetworkPolicy (Calico, Cilium). kind default (kindnet) does not support it. |
| **HPA** | Lab 10 requires metrics-server. Not installed on kind by default; see lab for install steps. |
| **Registry** | kind loads images directly. For AKS, push to ACR and update image refs in overlays. |

---

## Document Conventions

**No magic steps.** No step may say "configure as needed" without giving a concrete example. Every instruction must be actionable with specific values or commands.
