# Lab 9: NetworkPolicy Blocks Traffic

NetworkPolicy blocks web→api traffic; diagnose and fix.

## Goal

- Introduce a policy that blocks traffic from orders-web to orders-api
- Observe connection failures
- Fix by correcting the NetworkPolicy

## Prerequisites

- CNI with NetworkPolicy support (Calico, Cilium, etc.). kind default is kindnet; check with `kubectl get networkpolicies -A`.
- Dev overlay deployed with networkpolicy base

## Steps

### 1. Verify current policy

```bash
kubectl get networkpolicy -n dev
kubectl describe networkpolicy allow-web-to-api -n dev
```

The policy `allow-web-to-api` allows ingress to `app: orders-api` from `app: orders-web`.

### 2. Break the policy

Change the policy so it no longer allows web→api. For example, change the `from` selector to match no pods:

```bash
kubectl patch networkpolicy allow-web-to-api -n dev --type=merge -p '
{
  "spec": {
    "ingress": [{
      "from": [{
        "podSelector": {
          "matchLabels": {"app": "orders-web-nonexistent"}
        }
      }],
      "ports": [{"protocol": "TCP", "port": 5000}]
    }]
  }
}'
```

Now no pods match the ingress rule, so orders-api gets no allowed traffic (with default-deny-ingress).

### 3. Observe the failure

From orders-web, traffic to orders-api will fail. If the ingress routes `/api` to orders-api:

```bash
# Get orders-web pod
WEB_POD=$(kubectl get pods -n dev -l app=orders-web -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n dev $WEB_POD -- wget -qO- --timeout=2 http://orders-api.dev.svc.cluster.local:5000/healthz || echo "FAILED"
```

**Expected**: `FAILED` or connection timeout.

### 4. Diagnose

```bash
kubectl get networkpolicy allow-web-to-api -n dev -o yaml
```

Confirm `podSelector.matchLabels.app: orders-web-nonexistent` — no pods have that label.

### 5. Fix

Restore the correct selector. Option A — re-apply from Git:

```bash
kubectl apply -k deploy/overlays/dev
```

Option B — manual patch:

```bash
kubectl patch networkpolicy allow-web-to-api -n dev --type=merge -p '
{
  "spec": {
    "ingress": [{
      "from": [{
        "podSelector": {"matchLabels": {"app": "orders-web"}}
      }],
      "ports": [{"protocol": "TCP", "port": 5000}]
    }]
  }
}'
```

### 6. Verify

```bash
kubectl exec -n dev $WEB_POD -- wget -qO- --timeout=2 http://orders-api.dev.svc.cluster.local:5000/healthz
```

**Expected**: `OK` or healthy response.

---

## Why It Happened

- NetworkPolicy uses selectors. If the `from` selector matches no pods, no traffic is allowed. With default-deny-ingress, that means all ingress to orders-api is blocked.
- Common causes: typo in label, wrong namespace, policy applied to wrong namespace.

## How to Prevent It in a Platform

- **Policy as code**: Store NetworkPolicies in Git with the workloads; use Kustomize/Helm so selector labels stay in sync with deployments.
- **Conftest/Kyverno**: Validate that policy selectors reference existing labels.
- **Documentation**: Document the label scheme (`app`, `env`) and which policies allow which paths.
- **Integration tests**: E2E test that verifies web→api connectivity before and after policy changes.
