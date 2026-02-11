# Lab 11: Rolling Update Stuck — Readiness Probe

New pods never become Ready due to a broken readiness probe; fix and complete rollout.

## Goal

- Cause rollout to stall with a bad readiness probe path
- Diagnose why new pods stay Not Ready
- Fix the probe and complete the rollout

## Prerequisites

- Dev overlay deployed
- orders-api uses readinessProbe on `/readyz`

## Steps

### 1. Introduce a broken readiness probe

Patch the Deployment so the readiness probe hits a path that returns 404:

```bash
kubectl patch deployment orders-api -n dev --type=json -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/path", "value": "/nonexistent"}
]'
```

Or use the breakme overlay:

```bash
kubectl apply -k deploy/labs/breakme
# This applies dev + bad-probe patch (readinessProbe path: /nonexistent)
# If using breakme, work in namespace breakme
```

For dev namespace, the patch above is enough.

### 2. Observe stalled rollout

```bash
kubectl rollout status deployment orders-api -n dev
```

**Expected**: Command hangs (rollout never completes). Ctrl+C to exit.

```bash
kubectl get pods -n dev -l app=orders-api
kubectl get rs -n dev -l app=orders-api
```

**Expected output**:

```
NAME                          READY   STATUS    RESTARTS   AGE
orders-api-xxxxxxxxxx-aaaaa     1/1     Running   0          10m   # old
orders-api-yyyyyyyyyy-bbbbb     0/1     Running   0          2m    # new, NOT Ready
```

The new ReplicaSet's pods have `READY 0/1` because the readiness probe fails.

### 3. Diagnose

```bash
kubectl describe pod -n dev -l app=orders-api | grep -A 20 "Readiness:"
```

Or check events:

```bash
kubectl describe pod -n dev -l app=orders-api
```

**Expected (events)**:

```
Readiness probe failed: HTTP probe failed with statuscode: 404
```

The probe hits `/nonexistent` which returns 404, so the pod never becomes Ready.

### 4. Fix

**Option A — Fix the probe path in Git and re-apply**

Edit `deploy/base/orders-api/deployment.yaml` (or remove the bad patch) so readinessProbe uses `/readyz`:

```yaml
readinessProbe:
  httpGet:
    path: /readyz
    port: 5000
```

Then:

```bash
kubectl apply -k deploy/overlays/dev
```

**Option B — Quick rollback**

```bash
kubectl rollout undo deployment orders-api -n dev
```

This reverts to the previous ReplicaSet (with the correct probe).

### 5. Verify (if you fixed the probe)

```bash
kubectl rollout status deployment orders-api -n dev
kubectl get pods -n dev -l app=orders-api
```

**Expected**:

```
deployment "orders-api" successfully rolled out
NAME                          READY   STATUS    RESTARTS   AGE
orders-api-zzzzzzzzzz-xxxxx    1/1     Running   0          30s
```

---

## Why It Happened

- A Deployment's rolling update creates new pods. They must pass the readiness probe to receive traffic. If the probe fails (wrong path, wrong port, slow startup), pods stay Not Ready.
- `maxUnavailable: 0` means no old pods are terminated until new ones are Ready, so the rollout stalls.
- Common causes: probe path doesn't exist (`/health` vs `/healthz`), probe too aggressive (fails before app is ready), wrong port.

## How to Prevent It in a Platform

- **Golden path template**: Use standard probe paths (`/healthz`, `/readyz`) in the service template.
- **Smoke tests**: Verify probe endpoints exist before deploy (e.g. in Docker build or E2E).
- **Documentation**: Document probe contracts; readiness = "ready for traffic", liveness = "alive".
- **Admission**: Kyverno policy to require liveness and readiness probes on Deployments (see `platform/guardrails/kyverno-policies.yaml`).
