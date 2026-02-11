# Lab 7: DNS Failure Simulation and Debugging

Simulate DNS resolution failure and restore it.

## Goal

- Confirm DNS is broken from within a pod
- Identify root cause (CoreDNS down, NetworkPolicy, etc.)
- Restore DNS resolution

## Prerequisites

- Dev overlay deployed (orders-api, postgres, etc.)
- kind or k3d cluster

## Steps

### 1. Verify DNS works

```bash
kubectl run dns-test --image=busybox -it --rm --restart=Never -n dev -- nslookup postgres.dev.svc.cluster.local
```

**Expected output**:

```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      postgres.dev.svc.cluster.local
Address 1: 10.244.x.x
```

### 2. Simulate DNS failure

**Option A (kind/k3d): Scale CoreDNS to 0**

```bash
kubectl scale deployment coredns -n kube-system --replicas=0
# Or on some clusters: coredns -n kube-system, or kube-dns
kubectl get deployment -n kube-system | grep -E "coredns|kube-dns"
```

**Option B (k3d):** k3d uses CoreDNS in `kube-system`. Same command.

**Option C:** If your cluster uses a different DNS name, check:

```bash
kubectl get svc -n kube-system | grep dns
kubectl get deployment -n kube-system
```

### 3. Confirm DNS is broken

```bash
kubectl run dns-test --image=busybox -it --rm --restart=Never -n dev -- nslookup postgres.dev.svc.cluster.local
```

**Expected output**:

```
Server:    10.96.0.10
Address 1: 10.96.0.10

** server can't find postgres.dev.svc.cluster.local: NXDOMAIN
command terminated with exit code 1
```

Or timeout / `no such host`.

### 4. Diagnose

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
# or
kubectl get pods -n kube-system -l k8s-app=core-dns
```

**Expected**: 0 pods, or pods in CrashLoopBackOff.

```bash
kubectl get deployment -n kube-system coredns -o wide
# or kube-dns
```

**Expected**: `DESIRED 0` or `READY 0/0`.

### 5. Fix

Restore CoreDNS:

```bash
kubectl scale deployment coredns -n kube-system --replicas=1
# Adjust deployment name if your cluster uses kube-dns
```

### 6. Verify

```bash
kubectl run dns-test --image=busybox -it --rm --restart=Never -n dev -- nslookup postgres.dev.svc.cluster.local
```

**Expected**: Resolution succeeds again.

### 7. Check application recovery

orders-api uses postgres DNS name. If it was running during the outage, it may have cached connections. Restart to force reconnect:

```bash
kubectl rollout restart deployment orders-api -n dev
kubectl rollout status deployment orders-api -n dev
```

---

## Why It Happened

- CoreDNS (or kube-dns) is the cluster DNS server. Pods resolve `svc.namespace.svc.cluster.local` through it. When it's scaled to 0, no resolver is available.
- Other causes: NetworkPolicy blocking egress to kube-dns (UDP/TCP 53), DNS pods OOMKilled, misconfigured Corefile.

## How to Prevent It in a Platform

- **DNS pod disruption budget**: Prevent scaling CoreDNS to 0 accidentally; use PDB with minAvailable: 1.
- **NetworkPolicy**: Ensure app namespaces have egress to `kube-system` for DNS (UDP/TCP 53) and to the DNS service.
- **Monitoring**: Alert when DNS resolution fails from a synthetic probe (e.g. periodic nslookup from a DaemonSet).
- **Runbook**: Document DNS architecture and recovery steps (see `docs/runbooks/dns-issue.md`).
