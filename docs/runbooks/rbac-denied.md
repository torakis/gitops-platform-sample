# Runbook: RBAC Permission Denied

## Symptoms

- `kubectl` or in-cluster client gets: `User "..." cannot list resource "pods" in API group ""`
- Argo CD or app receives 403 from API server

## Diagnosis

### 1. Identify the subject

- User: from `kubectl auth whoami` or error message
- ServiceAccount: `system:serviceaccount:<ns>:<sa>`

### 2. Check RoleBinding

```bash
kubectl get rolebinding,clusterrolebinding -A
kubectl describe rolebinding <name> -n <namespace>
```

Verify the subject (user or ServiceAccount) is in `subjects`.

### 3. Check Role / ClusterRole

```bash
kubectl get role <name> -n <namespace> -o yaml
kubectl describe clusterrole <name>
```

Verify the role includes the required `verbs` and `resources`.

### 4. Common fixes

**ServiceAccount not bound**

Create Role and RoleBinding:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: my-role
  namespace: dev
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: my-binding
  namespace: dev
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: my-role
subjects:
- kind: ServiceAccount
  name: my-sa
  namespace: dev
```

**Wrong namespace**

Ensure RoleBinding is in the same namespace as the subject's ServiceAccount (for namespaced Role).
