# Deployment Patterns

Standard patterns used by the platform for deploying services.

## Pattern: Stateless API

- Deployment with replicas ≥ 1
- Service ClusterIP (or LoadBalancer for public APIs)
- Ingress for external traffic
- Liveness: HTTP GET /health/live
- Readiness: HTTP GET /health/ready (includes dependency checks)
- Resource requests/limits on every container
- HPA for CPU-based scaling (optional)

## Pattern: Worker / Background Job

- Deployment with replicas = 1 (or more if workload is partitionable)
- No Ingress
- Liveness: HTTP GET /health/live
- Readiness: optional (worker often always "ready")

## Pattern: Stateful Database

- StatefulSet or single Deployment with PVC
- No HPA (vertical scaling only for DB)
- Backup/restore runbooks documented

## Base Manifests

The `deploy/base/` directory implements these patterns for orders-api, orders-web, worker, and postgres.
