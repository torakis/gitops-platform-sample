# Runbook: Failed Deployment Rollout

## Symptoms

- `kubectl rollout status` hangs or reports failure
- New ReplicaSet not progressing
- Old pods terminating, new pods not becoming Ready

## Diagnosis

### 1. Check rollout status

```bash
kubectl rollout status deployment/orders-api -n dev
kubectl rollout history deployment/orders-api -n dev
```

### 2. Describe Deployment and ReplicaSet

```bash
kubectl describe deployment orders-api -n dev
kubectl get rs -n dev
kubectl describe rs <new-replicaset> -n dev
```

Look for:

- **Replicas**: desired vs current
- **Events**: why pods aren't scheduled or ready

### 3. Check new pods

```bash
kubectl get pods -n dev -l app=orders-api
kubectl describe pod <new-pod> -n dev
kubectl logs <new-pod> -n dev
```

### 4. Common causes

| Cause | Fix |
|-------|-----|
| Readiness probe failing | Adjust probe path, delay, or fix app health endpoint |
| Image pull failure | Fix image reference, registry auth |
| Resource limits too low | Increase requests/limits |
| Liveness killing pod | Increase `initialDelaySeconds` or fix app |

### 5. Rollback

```bash
kubectl rollout undo deployment/orders-api -n dev
```

Or to a specific revision:

```bash
kubectl rollout undo deployment/orders-api -n dev --to-revision=2
```

### 6. Pause rollout for investigation

```bash
kubectl rollout pause deployment/orders-api -n dev
# ... fix issues ...
kubectl rollout resume deployment/orders-api -n dev
```
