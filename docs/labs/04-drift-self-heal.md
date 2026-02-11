# Lab 4: Drift and Self-Heal

Manually edit a Deployment; Argo CD self-heals it back to Git state.

## Goal

- Introduce drift with `kubectl edit`
- Observe Argo CD revert the change automatically (self-heal)
- Understand why GitOps enforces desired state

## Prerequisites

- Lab 3 complete (Argo CD managing dev overlay)
- `selfHeal: true` in the Application sync policy

## Steps

### 1. Verify current state

```bash
kubectl get deployment orders-api -n dev -o jsonpath='{.spec.replicas}'
```

Expected: `1` (or whatever is in Git).

### 2. Introduce drift

Manually change replicas to 5:

```bash
kubectl edit deployment orders-api -n dev
# Change spec.replicas from 1 to 5, save and exit
```

### 3. Confirm drift

```bash
kubectl get deployment orders-api -n dev -o jsonpath='{.spec.replicas}'
kubectl get pods -n dev -l app=orders-api
```

**Expected output**:

```
5
NAME                          READY   STATUS    RESTARTS   AGE
orders-api-xxx-aaaaa          1/1     Running   0          10s
orders-api-xxx-bbbbb          1/1     Running   0          10s
orders-api-xxx-ccccc          1/1     Running   0          10s
orders-api-xxx-ddddd          1/1     Running   0          10s
orders-api-xxx-eeeee          1/1     Running   0          10s
```

Five replicas running.

### 4. Wait for self-heal

Argo CD polls (default ~3 min) or uses webhooks. Within a few minutes:

```bash
kubectl get deployment orders-api -n dev -o jsonpath='{.spec.replicas}'
kubectl get pods -n dev -l app=orders-api
```

**Expected output (after self-heal)**:

```
1
NAME                          READY   STATUS    RESTARTS   AGE
orders-api-xxx-aaaaa          1/1     Running   0          5m
```

Replicas reverted to 1. Argo CD reapplied the Git manifest and overwrote your manual change.

### 5. Observe Argo CD

In the Argo CD UI, you would see the app briefly "OutOfSync" and then "Synced" after the reconciliation.

---

## Why It Happened

- Argo CD continuously reconciles: it compares live cluster state to Git. When it detects drift, it reapplies the manifests from Git.
- `selfHeal: true` makes Argo CD *correct* drift automatically instead of only flagging it.

## How to Prevent Drift in a Platform

- **Self-heal**: Enable `selfHeal: true` for dev/staging so manual edits are quickly reverted.
- **RBAC**: Limit who can `kubectl edit`; prefer changes via Git.
- **Admission / OPA**: Consider blocking certain fields (e.g. image tags) so only Git can change them.
- **Audit**: Argo CD history shows what changed and when.
