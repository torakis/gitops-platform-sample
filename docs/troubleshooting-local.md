# Troubleshooting Local

Common issues and fixes for running the stack on macOS/Linux with k3d.

## Image Pull Errors

### Symptom

```bash
kubectl get pods -n dev
# orders-api-xxx   0/1   ImagePullBackOff   0   2m
```

```bash
kubectl describe pod -n dev -l app=orders-api
# Events:
#   Warning  Failed  Failed to pull image "orders-api:latest": rpc error: code = NotFound desc = ...
```

### Cause

Image not built or not loaded into k3d.

### Fix

```bash
./scripts/build-images-local.sh
```

Then restart rollout:

```bash
kubectl rollout restart deployment orders-api -n dev
kubectl rollout status deployment orders-api -n dev
```

### Verify

```bash
kubectl get pods -n dev -l app=orders-api
# READY 1/1, STATUS Running
```

---

## Ingress Not Reachable (dev.local)

### Symptom

```bash
curl -s http://dev.local/
# curl: (7) Failed to connect to dev.local port 80: Connection refused
# or: Connection timed out
```

### Causes

1. `dev.local` not in `/etc/hosts`
2. k3d loadbalancer not forwarding
3. Traefik or ingress misconfigured

### Fix 1: Add /etc/hosts

```bash
echo '127.0.0.1 dev.local' | sudo tee -a /etc/hosts
ping -c 1 dev.local
# Should resolve to 127.0.0.1
```

### Fix 2: Use port-forward instead

```bash
# Terminal 1: Web
kubectl port-forward svc/orders-web -n dev 3000:80
# Open http://localhost:3000

# Terminal 2: API
kubectl port-forward svc/orders-api -n dev 5000:5000
# Open http://localhost:5000/swagger
```

### Fix 3: Check ingress and Traefik

```bash
kubectl get ingress -n dev
# NAME              CLASS     HOSTS       ADDRESS   PORTS
# orders-ingress    traefik   dev.local   localhost 80

kubectl get svc -n kube-system | grep -i traefik
# traefik   LoadBalancer   ...   80/TCP
```

---

## Port-Forwarding

### Symptom

Need to reach Argo CD, orders-web, or orders-api when ingress fails.

### Commands

```bash
# Argo CD (get password first)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d && echo
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080 (accept self-signed cert)

# Orders web
kubectl port-forward svc/orders-web -n dev 3000:80
# Open http://localhost:3000

# Orders API
kubectl port-forward svc/orders-api -n dev 5000:5000
# Open http://localhost:5000/swagger
```

### Script

```bash
./scripts/port-forward.sh
# Prints all commands. Run each in a separate terminal.
```

---

## RBAC Forbidden

### Symptom

```
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:dev:orders-api"
cannot list resource "pods" in API group "" in the namespace "dev"
```

### Cause

ServiceAccount lacks permissions. Our base RBAC grants `orders-api` Role `get` and `list` on pods. If a different SA or missing RoleBinding, this appears.

### Fix

```bash
kubectl get role,rolebinding -n dev
# Ensure orders-api Role and RoleBinding exist
kubectl apply -k deploy/overlays/dev-k3d
# Re-applies RBAC from Git
```

---

## DNS Resolution Failure

### Symptom

Pods can't resolve `postgres.dev.svc.cluster.local`. Logs: "could not resolve host postgres".

### Cause

CoreDNS down or misconfigured.

### Fix

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
# If 0 replicas or CrashLoopBackOff:
kubectl scale deployment coredns -n kube-system --replicas=1
```

### Verify

```bash
kubectl run dns-test --image=busybox -it --rm -n dev -- nslookup postgres.dev.svc.cluster.local
# Should return an IP
```

---

## Argo CD App Stuck OutOfSync

### Symptom

```bash
argocd app get apps-dev
# SYNC STATUS: OutOfSync
```

### Causes

- Repo URL wrong (401/404)
- Path wrong (e.g. `deploy/overlays/dev` instead of `deploy/overlays/dev-k3d`)
- Branch/tag mismatch

### Fix

```bash
# Check repo URL and path
kubectl get application apps-dev -n argocd -o yaml | grep -A2 "source:"

# Hard refresh
argocd app sync apps-dev --force

# Or via kubectl
kubectl patch application apps-dev -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

---

## Postgres Connection Refused

### Symptom

orders-api pods CrashLoopBackOff. Logs: "connection refused" to postgres.

### Cause

Postgres not ready or secret missing.

### Fix

```bash
kubectl get pods -n dev -l app=postgres
# postgres-0 should be Running

kubectl get secret orders-db-secret -n dev
# Must exist (created by postgres StatefulSet manifest)

kubectl exec -n dev postgres-0 -c postgres -- pg_isready -U postgres
# Should print: accepting connections
```

---

## Windows Notes

- Use `./scripts/k3d-up.sh` from Git Bash or WSL. Native CMD/PowerShell may need `scripts\k3d-up.sh` (backslashes).
- Docker Desktop: Ensure "Use the WSL 2 based engine" if using WSL.
- `/etc/hosts` on Windows: `C:\Windows\System32\drivers\etc\hosts`. Add `127.0.0.1 dev.local` (run Notepad as Administrator to edit).
