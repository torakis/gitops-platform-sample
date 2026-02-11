# Service Template

Generic template for new services.

## Location

`templates/service-template/`

## Usage

1. Copy to `apps/<your-service>`
2. Follow [Golden Path](../../docs/golden-path.md)
3. Add to Kustomize overlays
4. Register in Argo CD (if applicable)

## Requirements

- Health endpoints: `/health/live`, `/health/ready`
- Resource requests/limits
- Non-root container user
