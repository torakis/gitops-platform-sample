# Lab 8: RBAC Denial — Forbidden Error

A ServiceAccount gets "forbidden" when listing pods; fix the RoleBinding.

## Goal

- Reproduce a 403 Forbidden for a ServiceAccount
- Diagnose missing permissions
- Fix by updating the Role

## Prerequisites

- Dev overlay deployed
- Base RBAC includes Role `orders-api` with `get`, `list` on pods

## Steps

### 1. Create a minimal ServiceAccount and restrictive Role

Apply this (or use `deploy/base/rbac` as reference):

```bash
kubectl create sa dev-reader -n dev --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: dev-reader
  namespace: dev
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get"]   # intentionally missing "list" and "watch"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-reader
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: dev-reader
subjects:
- kind: ServiceAccount
  name: dev-reader
  namespace: dev
EOF
```

### 2. Reproduce the denial

```bash
kubectl auth can-i list pods -n dev --as=system:serviceaccount:dev:dev-reader
```

**Expected output**:

```
no
```

### 3. Test from a pod (optional)

```bash
kubectl run rbac-test --image=bitnami/kubectl -it --rm --restart=Never -n dev \
  --overrides='{"spec":{"serviceAccountName":"dev-reader"}}' -- list pods
```

**Expected output**:

```
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:dev:dev-reader" cannot list resource "pods" in API group "" in the namespace "dev"
```

### 4. Diagnose

```bash
kubectl get role dev-reader -n dev -o yaml
kubectl get rolebinding dev-reader -n dev -o yaml
```

**Expected**: Role has only `verbs: ["get"]`; no `list`.

### 5. Fix

Update the Role to add `list` and `watch`:

```bash
kubectl patch role dev-reader -n dev --type=merge -p '
{
  "rules": [{
    "apiGroups": [""],
    "resources": ["pods"],
    "verbs": ["get", "list", "watch"]
  }]
}'
```

Or apply via manifest:

```yaml
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

### 6. Verify

```bash
kubectl auth can-i list pods -n dev --as=system:serviceaccount:dev:dev-reader
```

**Expected output**:

```
yes
```

---

## Why It Happened

- RBAC requires an explicit grant. The Role had only `get`; `list` requires its own verb. `kubectl get pods` and `list` API calls need the `list` verb.
- Common mistakes: missing verb, wrong resource name (e.g. `pod` vs `pods`), wrong apiGroup (e.g. `apps` for Deployment).

## How to Prevent It in a Platform

- **Platform-owned RBAC**: Provide pre-built Roles (e.g. `dev-reader`, `namespace-admin`) in Git; teams use RoleBindings only.
- **RBAC docs**: Document which verbs map to which operations (`list` for listing, `get` for single resource, etc.).
- **Automated tests**: CI job that runs `kubectl auth can-i` for expected operations before merge.
- **Least privilege**: Start minimal; add verbs when teams hit Forbidden, and record in runbooks.
