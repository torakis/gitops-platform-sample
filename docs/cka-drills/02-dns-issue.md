# CKA Drill 2: DNS Resolution Failure

**Scenario:** orders-api cannot connect to postgres. Logs show "could not resolve host postgres".

## Setup

1. Deploy dev overlay
2. Scale CoreDNS to 0: `kubectl scale deployment coredns -n kube-system --replicas=0` (kind/k3d)
3. Or add a NetworkPolicy that blocks egress to kube-dns

## Task

1. Confirm DNS is broken from within a pod
2. Identify the root cause
3. Restore DNS resolution

## Commands to practice

```bash
kubectl run debug --image=busybox -it --rm --restart=Never -- nslookup postgres.dev.svc.cluster.local
kubectl get svc -n kube-system
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl get networkpolicy -n dev -o yaml
```

## Solution

- **CoreDNS scaled down**: `kubectl scale deployment coredns -n kube-system --replicas=1` (adjust for your cluster)
- **NetworkPolicy**: Add egress rule for UDP/TCP 53 to kube-system or namespaceSelector {}
