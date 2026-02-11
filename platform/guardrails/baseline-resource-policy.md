# Baseline Resource Policy

Default requirements for all workloads. Enforced by platform tooling or policy engines where available.

## Requirements

### Every Deployment Must Have

| Field | Requirement |
|-------|-------------|
| `resources.requests.cpu` | Set; minimum 10m |
| `resources.requests.memory` | Set; minimum 32Mi |
| `resources.limits.cpu` | Set |
| `resources.limits.memory` | Set |
| `livenessProbe` | HTTP or exec; required |
| `readinessProbe` | HTTP or exec; required |

### Container Image

- No `:latest` in production overlays (use digest or explicit tag)
- Non-root user in Dockerfile
- Read-only root filesystem where feasible

### Secrets

- Do not bake secrets into images
- Use Kubernetes Secret or external store (e.g. Key Vault CSI)
- Never log secrets

### Networking

- Define NetworkPolicy where isolation required
- Prefer ClusterIP; LoadBalancer only when needed
