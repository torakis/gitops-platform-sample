# Labels and Annotations Standard

## Required Labels

| Label | Description | Example |
|-------|-------------|---------|
| `app` | Service name (must match selector) | `orders-api` |
| `env` | Environment | `dev`, `staging`, `prod` |

## Recommended Labels

| Label | Description |
|-------|-------------|
| `version` | Image tag or app version |
| `team` | Owning team |
| `part-of` | Parent application |

## Prometheus Annotations (for non-Operator scrape)

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "5000"
    prometheus.io/path: "/metrics"
```

## Argo CD Annotations

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-options: PruneLast
```

## Format

- Lowercase, hyphens
- Keys: `app`, `env`, `team` (no dots unless namespaced)
