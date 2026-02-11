# Lab 5: ImagePullBackOff — Bad Image Tag

Introduce a bad image tag, observe ImagePullBackOff, fix via GitOps.

## Goal

- Cause ImagePullBackOff by using a non-existent image
- Diagnose with `kubectl describe`
- Fix by updating the image in Git and syncing

## Prerequisites

- Dev overlay deployed, images built (`./scripts/local-registry.sh build`)

## Steps

### 1. Introduce a bad image tag

Patch the Deployment to use a non-existent image:

```bash
kubectl set image deployment/orders-api api=orders-api:nonexistent -n dev
```

### 2. Observe the failure

```bash
kubectl get pods -n dev -l app=orders-api
```

**Expected output**:

```
NAME                          READY   STATUS             RESTARTS   AGE
orders-api-xxxxxxxxxx-yyyyy    0/1     ImagePullBackOff    0          1m
```

### 3. Diagnose

```bash
kubectl describe pod -n dev -l app=orders-api
```

**Expected output** (Events section):

```
Events:
  Type     Reason     Message
  ----     ------     -------
  Normal   Scheduled  Successfully assigned dev/orders-api-xxx to kind-worker
  Warning  Failed     Failed to pull image "orders-api:nonexistent": rpc error: code = NotFound desc = failed to resolve reference "orders-api:nonexistent": not found
  Warning  Failed     Error: ErrImagePull
  Normal   BackOff    Back-off pulling image "orders-api:nonexistent"
  Warning  Failed     Error: ImagePullBackOff
```

### 4. Fix via GitOps

Edit `deploy/base/orders-api/deployment.yaml` (or add an overlay patch) to use the correct image:

```yaml
# Ensure image is orders-api:latest (or your actual tag)
containers:
- name: api
  image: orders-api:latest
```

Then apply (or push and let Argo sync):

```bash
kubectl apply -k deploy/overlays/dev
```

**If using Argo CD**: Commit and push; Argo CD will sync, or run `argocd app sync apps-dev`.

### 5. Verify recovery

```bash
kubectl get pods -n dev -l app=orders-api
kubectl rollout status deployment/orders-api -n dev
```

**Expected output**:

```
NAME                          READY   STATUS    RESTARTS   AGE
orders-api-xxxxxxxxxx-zzzzz    1/1     Running   0          30s
deployment "orders-api" successfully rolled out
```

---

## Why It Happened

- The image `orders-api:nonexistent` does not exist in the registry (or local kind registry). The kubelet cannot pull it, so the pod stays in `ImagePullBackOff`.
- Common causes: typo in tag, image not pushed, wrong registry, authentication failure.

## How to Prevent It in a Platform

- **CI/CD gates**: Only allow tags that exist (e.g. build pipeline updates manifest with digest after push).
- **Digest pinning**: Use `image: orders-api@sha256:...` instead of tags to avoid tag moves.
- **Admission policies**: Kyverno/OPA to reject `:latest` in prod or unknown tags.
- **GitOps image update**: Use Renovate/ImgBot or CI to update image tags in deploy repo after build.
