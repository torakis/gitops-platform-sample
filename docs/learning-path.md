# Learning Path

A step-by-step guide for hands-on learning with gitops-platform-sample.

## Prerequisites

| Tool | Purpose |
|------|---------|
| Docker | Containers, local K8s |
| kubectl | Kubernetes CLI |
| kind or k3d | Local Kubernetes |
| .NET 8 SDK | orders-api, worker |
| Node.js 20+ | orders-web |
| Terraform ≥ 1.5 | Azure provisioning (optional) |
| Azure CLI | `az login` for Terraform (optional) |

## Path Overview

```
Lab 1: Local K8s + Argo CD     → Get apps running locally
Lab 2: GitOps Flow             → Change manifests, observe sync
Lab 3: Terraform (Azure)       → Provision AKS, ACR
Lab 4: Platform                → Environments, policies, observability
Lab 5: Golden Path             → Add a new service from template
Lab 6: CKA Drills              → Troubleshoot real failure scenarios
```

## Lab 1: Local Kubernetes

1. Run `./scripts/kind-bootstrap.sh` (or `k3d-bootstrap.sh`)
2. Build and load images: `./scripts/local-registry.sh build`
3. Apply dev overlay: `kubectl apply -k deploy/overlays/dev`
4. Add `127.0.0.1 dev.local` to `/etc/hosts` (run `make print-hosts` for the exact line)
5. Open http://dev.local

**Learn:** Namespaces, Deployments, Services, Ingress, health probes.

## Lab 2: GitOps Flow

1. Change a replica count in `deploy/overlays/dev/kustomization.yaml`
2. Commit and push (or apply locally)
3. Watch Argo CD sync (if using Argo CD) or `kubectl get pods -n dev -w`
4. Understand: Git as source of truth, declarative config

## Lab 3: Terraform

1. Copy `terraform/dev/dev.tfvars.example` to `dev.tfvars`
2. Set `acr_name` (must be globally unique)
3. `terraform init` and `terraform apply -var-file=dev.tfvars`
4. `az aks get-credentials -g <rg> -n <cluster>`
5. Deploy Argo CD and applications

**Learn:** IaC, Azure resources, remote state.

## Lab 4: Platform

1. Explore `platform/environments`, `platform/policies`, `platform/observability`
2. Apply NetworkPolicies and see traffic restrictions
3. Review RBAC in `platform/policies/rbac-reader.yaml`

**Learn:** Platform responsibilities, security, multi-tenancy.

## Lab 5: Golden Path

1. Copy `templates/service-template` to `apps/my-service`
2. Follow `docs/golden-path.md` onboarding steps
3. Add Kustomize base and overlay
4. Register in Argo CD apps

**Learn:** Self-service, consistency, templates.

## Lab 6: Debugging Labs

Work through `docs/labs/` for step-by-step exercises:

| Lab | Scenario |
|-----|----------|
| 03 | GitOps basics — change in Git, Argo syncs |
| 04 | Drift + self-heal — kubectl edit reverted |
| 05 | ImagePullBackOff — fix bad image via GitOps |
| 06 | Broken Service selector — no endpoints |
| 07 | DNS failure — simulate and debug |
| 08 | RBAC denial — fix Role/RoleBinding |
| 09 | NetworkPolicy blocks traffic |
| 10 | HPA not scaling — missing metrics |
| 11 | Rolling update stuck — readiness probe |
| 12 | Terraform drift — detect and reconcile |

Each lab includes: goal, commands, expected outputs, "why it happened," and platform prevention tips.

See also `docs/cka-drills/` for condensed troubleshooting scenarios.
