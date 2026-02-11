# CKA Drill 1: Broken Service

**Scenario:** orders-api pods are not starting. Diagnose and fix.

## Setup (instructor / script)

1. Deploy dev overlay
2. Corrupt the image tag: `kubectl set image deployment/orders-api api=orders-api:bad -n dev`
3. Or delete the postgres secret: `kubectl delete secret orders-db-secret -n dev`

## Task

1. Identify why pods are not Ready
2. Fix the issue
3. Confirm all pods are Running and Ready

## Commands to practice

```bash
kubectl get pods -n dev
kubectl describe pod <name> -n dev
kubectl logs <pod> -n dev
kubectl get events -n dev --sort-by='.lastTimestamp'
```

## Solution

- **Bad image**: Revert image to `orders-api:latest` or correct tag
- **Missing secret**: Re-apply base postgres (which creates the secret) or restore secret manually
