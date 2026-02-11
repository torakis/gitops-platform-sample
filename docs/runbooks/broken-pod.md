# Runbook: Pod Not Starting

## Symptoms

- Pod stuck in `Pending`, `CrashLoopBackOff`, or `Error`
- `kubectl get pods` shows non-Ready status

## Diagnosis

### 1. Describe the pod

```bash
kubectl describe pod <pod-name> -n <namespace>
```

Look for:

- **Events** — scheduling, image pull, container start errors
- **Conditions** — Ready, ContainersReady

### 2. Check logs

```bash
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous  # if restarted
```

### 3. Common causes

| Cause | Event / Log | Fix |
|-------|-------------|-----|
| ImagePullBackOff | `Failed to pull image` | Check image name, registry auth, network |
| CrashLoopBackOff | App crash in logs | Fix app bug, adjust probes |
| Pending | `0/X nodes available` | Insufficient CPU/memory, taints |
| CreateContainerConfigError | Missing secret/configmap | Create secret/configmap |

### 4. Fixes

**ImagePullBackOff**

- Verify image exists: `docker pull <image>`
- For private registry: create `imagePullSecrets`
- Check `imagePullPolicy`

**CrashLoopBackOff**

- Increase `initialDelaySeconds` on probes if app starts slowly
- Check startup logs for connection strings, missing env vars

**Pending**

- Check node resources: `kubectl describe nodes`
- Check resource requests vs cluster capacity
- Relax ResourceQuota if in place
