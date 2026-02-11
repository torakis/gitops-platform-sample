# CKA Drill 4: Failed Rollout

**Scenario:** A new deployment of orders-api is stuck. New pods never become Ready.

## Setup

1. Deploy dev overlay
2. Change readiness probe to a wrong path: patch deployment so readiness probe hits `/nonexistent`
3. Apply: `kubectl apply -k deploy/overlays/dev` with the broken probe

## Task

1. Observe rollout status
2. Find why new pods are not Ready
3. Fix the probe and complete the rollout
4. Optionally practice rollback

## Commands to practice

```bash
kubectl rollout status deployment/orders-api -n dev
kubectl rollout history deployment/orders-api -n dev
kubectl get rs -n dev
kubectl describe pod <new-pod> -n dev
kubectl logs <new-pod> -n dev
kubectl rollout undo deployment/orders-api -n dev
```

## Solution

- Fix readiness probe path to `/health/ready` (or correct path)
- Or rollback: `kubectl rollout undo deployment/orders-api -n dev`
