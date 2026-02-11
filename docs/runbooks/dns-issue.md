# Runbook: DNS Resolution Failure

## Symptoms

- Pods cannot resolve service names (e.g. `postgres`, `orders-api`)
- Logs show "could not resolve host" or connection refused to hostname

## Diagnosis

### 1. Test DNS from a pod

```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup postgres.dev.svc.cluster.local
```

Expected: IP address returned.

### 2. Check CoreDNS

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### 3. Verify Service exists

```bash
kubectl get svc -n <namespace>
```

Service name must match what the app uses. Kubernetes DNS format:

- Same namespace: `postgres`
- Other namespace: `postgres.dev.svc.cluster.local`

### 4. Common causes

| Cause | Fix |
|-------|-----|
| Wrong service name | Use exact Service name (case-sensitive) |
| Wrong namespace | Use FQDN or ensure app runs in same namespace |
| CoreDNS down | Restart CoreDNS pods, check node resources |
| NetworkPolicy blocking | Allow egress to kube-dns (port 53) |

### 5. NetworkPolicy egress

If NetworkPolicy is applied, ensure egress to DNS:

```yaml
egress:
- to:
  - namespaceSelector: {}
  ports:
  - protocol: UDP
    port: 53
  - protocol: TCP
    port: 53
```
