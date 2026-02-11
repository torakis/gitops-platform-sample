# Lab 10: HPA Not Scaling — Missing Metrics

HPA fails to scale because metrics-server or custom metrics are unavailable.

## Goal

- Deploy HPA and observe it not scaling
- Diagnose missing metrics (metrics-server not installed, or wrong metric type)
- Fix by installing metrics-server or correcting the HPA

## Prerequisites

- Prod overlay (has HPA) or apply HPA to dev for this lab
- orders-api deployment with resource requests set

## Steps

### 1. Deploy with HPA

Use prod overlay (which includes HPA), or add HPA to dev. For a minimal test:

```bash
# Ensure metrics-server is installed (often missing on kind)
kubectl get deployment metrics-server -n kube-system 2>/dev/null || echo "metrics-server not found"
```

### 2. Apply HPA

```bash
kubectl apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: orders-api-hpa
  namespace: dev
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: orders-api
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
EOF
```

### 3. Check HPA status

```bash
kubectl get hpa orders-api-hpa -n dev
```

**Expected output (when metrics-server is missing)**:

```
NAME              REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
orders-api-hpa   Deployment/orders-api <unknown>/70%   1         5         1          1m
```

`TARGETS` shows `<unknown>/70%` — HPA cannot read CPU utilization.

### 4. Diagnose

```bash
kubectl describe hpa orders-api-hpa -n dev
```

**Expected (in Conditions)**:

```
Conditions:
  Type           Status  Reason                   Message
  ----           ------  ------                   -------
  AbleToScale    True    SucceededGetScale        the HPA controller was able to get the target's current scale
  ScalingActive  False   FailedGetResourceMetric  the HPA was unable to compute the replica count: unable to get metrics for resource cpu: no metrics returned from resource metrics API
```

The "resource metrics API" is provided by metrics-server. Without it, HPA cannot scale on CPU/memory.

### 5. Fix — Install metrics-server

**kind**:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# Fix for kind (insecure TLS for local clusters):
kubectl patch deployment metrics-server -n kube-system --type=json -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

Wait for metrics-server to be ready:

```bash
kubectl rollout status deployment metrics-server -n kube-system
```

### 6. Verify HPA works

```bash
sleep 30  # Allow metrics to populate
kubectl get hpa orders-api-hpa -n dev
```

**Expected output**:

```
NAME              REFERENCE            TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
orders-api-hpa   Deployment/orders-api 12%/70%   1         5         1          5m
```

`TARGETS` now shows actual CPU (e.g. `12%/70%`). Under load, HPA would scale up.

### 7. Optional — Test scaling

Generate load to trigger scale-up:

```bash
kubectl run load-generator --image=busybox -n dev --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://orders-api:5000/api/orders; done"
# Watch HPA and pods
kubectl get hpa -n dev -w
```

---

## Why It Happened

- HPA uses the resource metrics API (CPU, memory) or custom metrics (Prometheus, etc.). The resource metrics API is served by metrics-server.
- On minimal clusters (kind, k3d), metrics-server is often not installed by default. HPA then shows `<unknown>` and never scales.
- For custom metrics (e.g. `pods` or `external`), Prometheus Adapter must be installed and configured.

## How to Prevent It in a Platform

- **Bootstrap**: Include metrics-server in cluster bootstrap (kind/k3d scripts, AKS has it by default).
- **Validation**: Startup check that `kubectl top nodes` works before enabling HPA.
- **Documentation**: Document that HPA requires metrics-server for CPU/memory; custom metrics require Prometheus Adapter.
- **Platform template**: When adding HPA to an overlay, ensure metrics-server is a platform dependency.
