# Service Template

Copy this folder to `apps/<your-service-name>` and follow the golden path.

## Contents

- `Dockerfile` — Multi-stage build
- `app/` — Placeholder for .NET or Node app
- `deploy/base/` — Kustomize base (reference)

## Naming

Replace `my-service` with your service name in:

- Dockerfile
- deployment.yaml
- kustomization.yaml

## Requirements

- Expose `/health/live` and `/health/ready`
- Set resource requests/limits
- Use non-root user in container
