# Environment Definitions

## Naming Convention

- `dev` — Development; shared; ephemeral
- `staging` — Pre-production; mirrors prod
- `prod` — Production; strict policies

## Labels (Applied to Namespaces)

| Label | dev | staging | prod |
|-------|-----|---------|------|
| `env` | dev | staging | prod |
| `tier` | development | preprod | production |
| `allow-autoscaling` | "true" | "true" | "true" |

## Resource Quotas (Examples)

- **dev**: relaxed; 4 CPU, 8Gi memory per namespace
- **staging**: moderate; 8 CPU, 16Gi per namespace
- **prod**: strict; 16 CPU, 32Gi per namespace (varies by team)

## Namespace Strategy

- One namespace per app team (e.g. `orders-dev`, `orders-staging`, `orders-prod`)
- Or single namespace per env (e.g. `dev`, `staging`, `prod`) with prefix for resources

This repo uses **single namespace per env** for simplicity.
