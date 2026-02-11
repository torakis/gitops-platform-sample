# CKA Drill 3: RBAC Denied

**Scenario:** A developer ServiceAccount cannot list pods in the dev namespace.

## Setup

1. Create ServiceAccount: `kubectl create sa dev-reader -n dev`
2. Create Role with only `get` (no `list`): apply a restrictive Role
3. Create RoleBinding
4. Test: `kubectl auth can-i list pods -n dev --as=system:serviceaccount:dev:dev-reader` → no

## Task

1. Verify the denial
2. Update RBAC so the ServiceAccount can list pods
3. Confirm: `kubectl auth can-i list pods -n dev --as=system:serviceaccount:dev:dev-reader` → yes

## Commands to practice

```bash
kubectl auth can-i list pods -n dev --as=system:serviceaccount:dev:dev-reader
kubectl get role,rolebinding -n dev
kubectl describe role <name> -n dev
```

## Solution

Update the Role to add `list` and `watch` for pods:

```yaml
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```
