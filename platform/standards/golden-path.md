# Golden Path: New Microservice

End-to-end flow from scaffold to production. Runnable locally and on kind/k3d; AKS optional.

---

## 1. Scaffold

```bash
cp -r platform/standards/service-template apps/my-service
cd apps/my-service
# Rename: MyService.csproj, namespace, assembly
```

**Checklist:**
- [ ] Service name (alphanumeric, lowercase)
- [ ] `/healthz`, `/readyz` present
- [ ] Prometheus `/metrics` if applicable

---

## 2. Build

```bash
dotnet restore
dotnet build -c Release
dotnet run   # Local test
```

**CI:** Add to `.github/workflows/dotnet-build.yml` matrix.

---

## 3. Container

```bash
docker build -t my-service:latest .
docker run -p 8080:8080 my-service:latest
curl http://localhost:8080/healthz
```

**Requirements:**
- Multi-stage build
- Non-root user
- Health probes exposed

---

## 4. Deploy

Create `deploy/base/my-service/`:

- `deployment.yaml` — Deployment, Service
- `kustomization.yaml`

Add to overlay:

```yaml
# deploy/overlays/dev/kustomization.yaml
resources:
- ../../base/my-service
```

Apply:

```bash
kubectl apply -k deploy/overlays/dev
```

**Argo CD:** Add Application in `argocd/applications/apps-app.yaml`.

---

## 5. Observe

- **Logs:** `kubectl logs -f deployment/my-service -n dev`
- **Metrics:** Expose `/metrics`; ServiceMonitor or Prometheus scrape config
- **Health:** Liveness/readiness probes; /healthz, /readyz

**Metrics to expose (RED):**
- Request rate, errors, duration
- Use `prometheus-net` or equivalent

---

## Summary

| Phase   | Action                    | Tool / Location                     |
|---------|---------------------------|-------------------------------------|
| Scaffold| Copy template             | `platform/standards/service-template` |
| Build   | Compile, test             | `dotnet build`, CI                  |
| Container| Docker build             | `Dockerfile`                        |
| Deploy  | Kustomize + overlay       | `deploy/base/`, `deploy/overlays/`  |
| Observe | Logs, metrics, probes     | kubectl, Prometheus, Grafana         |
