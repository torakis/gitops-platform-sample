# Service Template (Minimal API)

Scaffold for a new .NET 8 minimal API microservice. Copy to `apps/<name>` and customize.

## Contents

- `Program.cs` — Health endpoints, `/api/hello`, Prometheus metrics
- `MyService.csproj` — Dependencies
- `Dockerfile` — Multi-stage, non-root
- `deploy.yaml` — Kustomize base (reference)

## Quick Start

```bash
cp -r platform/standards/service-template apps/my-service
cd apps/my-service
# Rename MyService -> MyService, update namespaces
dotnet run
# curl http://localhost:5000/healthz
# curl http://localhost:5000/api/hello?name=dev
```

## Golden Path

See `platform/standards/golden-path.md` for the full flow.
