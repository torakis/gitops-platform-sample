# Platform Team Definitions

This folder contains how the platform team defines environments, policies, observability, and deployment patterns. Developers consume these through GitOps and the golden path.

## Structure

| Path | Purpose |
|------|---------|
| `environments/` | Environment definitions (dev, staging, prod) with quotas, labels, naming |
| `policies/` | NetworkPolicy, RBAC, Pod Security, resource defaults |
| `observability/` | ServiceMonitor, logging, dashboards, alerts |
| `deployment-patterns/` | Standard patterns for Deployments, Services, Ingress |

## Usage

- **Argo CD bootstrap** applies platform components (observability, policies) before applications.
- **Overlays** in `deploy/overlays/{env}` reference these definitions where applicable.
- **Developers** follow the golden path; they do not need to understand every policy file.
