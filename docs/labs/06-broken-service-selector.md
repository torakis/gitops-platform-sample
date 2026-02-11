# Lab 6: Broken Service Selector — No Endpoints

Break the Service selector so it no longer matches pods; diagnose and fix.

## Goal

- Cause the orders-api Service to have no endpoints
- Diagnose with `kubectl get endpoints` and `describe`
- Fix by aligning selector with pod labels

## Prerequisites

- Dev overlay deployed, orders-api running

## Steps

### 1. Break the selector

Edit the Service so its selector does not match the Deployment's pod template labels:

```bash
kubectl patch svc orders-api -n dev -p '{"spec":{"selector":{"app":"orders-api-broken"}}}'
```

### 2. Observe the symptom

```bash
# Pods are still running
kubectl get pods -n dev -l app=orders-api

# But Service has no endpoints
kubectl get endpoints orders-api -n dev
```

**Expected output**:

```
# pods
NAME                          READY   STATUS    RESTARTS   AGE
orders-api-xxxxxxxxxx-xxxxx    1/1     Running   0          5m

# endpoints
NAME         ENDPOINTS   AGE
orders-api   <none>      10m
```

`ENDPOINTS` is empty. Traffic to the Service will fail (connection refused or timeout).

### 3. Diagnose

```bash
kubectl get svc orders-api -n dev -o yaml
kubectl get pods -n dev -l app=orders-api -o jsonpath='{.items[0].metadata.labels}'
```

**Expected**:
- Service selector: `app: orders-api-broken`
- Pod labels: `app: orders-api`

They don't match, so the Service finds no pods.

### 4. Fix

Restore the correct selector. Option A — apply from Git:

```bash
kubectl apply -k deploy/overlays/dev
```

Option B — manual patch:

```bash
kubectl patch svc orders-api -n dev -p '{"spec":{"selector":{"app":"orders-api"}}}'
```

### 5. Verify

```bash
kubectl get endpoints orders-api -n dev
```

**Expected output**:

```
NAME         ENDPOINTS              AGE
orders-api   10.244.x.x:5000        10m
```

Endpoints populated; traffic flows again.

---

## Why It Happened

- Kubernetes Services route traffic to pods whose labels match `spec.selector`. If the selector doesn't match any pods, there are no endpoints, and the Service IP returns no backends.
- Common causes: typo in selector, Deployment uses different labels (e.g. `app.kubernetes.io/name` vs `app`), copy-paste error.

## How to Prevent It in a Platform

- **Shared Kustomize base**: Service and Deployment in the same base with `commonLabels` so selector and pod labels stay aligned.
- **Validators**: Conftest or Kyverno to ensure Service selector is a subset of Deployment pod template labels.
- **E2E tests**: Smoke test that hits the Service and verifies responses.
- **Golden path template**: Service + Deployment in platform service-template with matching labels by default.
