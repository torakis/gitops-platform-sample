# Namespace Conventions

## Naming

| Pattern | Example | Purpose |
|---------|---------|---------|
| `{env}` | `dev`, `staging`, `prod` | Environment-based |
| `{team}-{env}` | `orders-dev`, `orders-prod` | Team + env |
| `{app}-{env}` | `orders-api-dev` | App-scoped (less common) |

This repo uses **environment-based**: `dev`, `staging`, `prod`.

## Labels (on namespace)

| Label | Values | Purpose |
|-------|--------|---------|
| `env` | dev, staging, prod | Environment |
| `tier` | development, preprod, production | Tier |
| `platform/owner` | team-name | Ownership |

## Lifecycle

- **dev**: Ephemeral; can be recreated
- **staging**: Mirrors prod; used for pre-release validation
- **prod**: Protected; changes require approval
