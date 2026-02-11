# Orders Application

## Overview

Microservices for order management: API, Web UI, Worker, PostgreSQL.

## Services

| Service    | Repo Path     | Port | Description                |
|------------|---------------|------|----------------------------|
| orders-api | apps/orders-api | 5000 | REST API for orders        |
| orders-web | apps/orders-web | 8080 | React SPA                  |
| worker     | apps/worker     | 5001 | Background order processor |
| postgres   | deploy/base/postgres | 5432 | Database                 |

## Deploy

- **Local**: `kubectl apply -k deploy/overlays/dev`
- **Argo CD**: applications-dev, applications-staging, applications-prod

## Runbooks

- [Broken Pod](../../docs/runbooks/broken-pod.md)
- [DNS Issue](../../docs/runbooks/dns-issue.md)
- [Failed Rollout](../../docs/runbooks/failed-rollout.md)
