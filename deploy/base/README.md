# Base Manifests

Shared Kubernetes resources. Use overlays for environment-specific config.

## Contents

| Path | Description |
|------|-------------|
| `orders-api/` | API Deployment, Service, ConfigMap |
| `orders-web/` | Web Deployment, Service |
| `worker/` | Worker Deployment, Service |
| `postgres/` | StatefulSet + PVC (dev only) |
| `rbac/` | ServiceAccounts, Roles, RoleBindings |
| `networkpolicy/` | NetworkPolicies: web→api, api→db |
| `overlays/*/ingress.yaml` | Ingress per overlay (host in overlay) |

## Postgres: Dev vs Staging/Prod

| Environment | Database | Secret |
|-------------|----------|--------|
| **dev** | In-cluster StatefulSet + PVC | Created by postgres base |
| **staging** | Managed DB (e.g. Azure PostgreSQL, RDS) | External `orders-db-secret` |
| **prod** | Managed DB | External `orders-db-secret` |

See [deploy/docs/managed-db.md](docs/managed-db.md) for staging/prod setup. Optional: [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets).
