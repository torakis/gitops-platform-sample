# Golden Path: Adding a New Service

The platform's recommended way to add a new service.

## Overview

```
1. Copy service template
2. Implement your service
3. Add Kustomize base + overlay
4. Register in Argo CD (or document for platform team)
5. CI/CD: add build + image push
```

## Step 1: Copy the Template

```bash
cp -r templates/service-template apps/my-new-service
cd apps/my-new-service
```

## Step 2: Customize

- Replace placeholder names in code and config
- Add your endpoints, logic, dependencies
- Ensure health endpoints: `/health/live`, `/health/ready`

## Step 3: Add Kustomize Manifests

Create `deploy/base/my-new-service/` with:

- `deployment.yaml` — Deployment, Service
- `kustomization.yaml` — references deployment

Create or update `deploy/overlays/dev/kustomization.yaml`:

```yaml
resources:
- ../../base/my-new-service
```

## Step 4: Register in Argo CD

Add an Application to `argocd/applications/apps-app.yaml` or create a new Application manifest that points to your overlay.

## Step 5: CI/CD

- Add your service to `.github/workflows/dotnet-build.yml` or `react-build.yml` if applicable
- Add to `.github/workflows/build-push-images.yml` matrix
- Update `.github/workflows/gitops-update.yml` if using automated tag updates

## Checklist

- [ ] Health checks (liveness, readiness)
- [ ] Resource requests and limits
- [ ] Non-root container user (Dockerfile)
- [ ] Secrets via Secret/ConfigMap, not baked in
- [ ] NetworkPolicy if needed (platform team can add)

## Getting Help

- See `portal/catalog/` for service catalog
- Runbooks: `docs/runbooks/`
- Platform team: #platform-support
