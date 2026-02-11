# Labs — Step-by-Step Exercises

Hands-on labs for GitOps, Kubernetes debugging, and platform engineering.

| Lab | Topic |
|-----|-------|
| [01-local-k8s](01-local-k8s.md) | Bootstrap kind/k3d, deploy dev overlay |
| [02-gitops-flow](02-gitops-flow.md) | GitOps concepts: change manifests, sync |
| [03-gitops-basics](03-gitops-basics.md) | Change desired state in Git, Argo syncs |
| [04-drift-self-heal](04-drift-self-heal.md) | Drift: manual kubectl edit; Argo self-heals |
| [05-image-pull-backoff](05-image-pull-backoff.md) | Bad image tag → ImagePullBackOff; fix via GitOps |
| [06-broken-service-selector](06-broken-service-selector.md) | Broken Service selector → no endpoints; diagnose |
| [07-dns-failure](07-dns-failure.md) | DNS failure simulation and debugging |
| [08-rbac-denial](08-rbac-denial.md) | RBAC forbidden; fix Role/RoleBinding |
| [09-networkpolicy-blocks](09-networkpolicy-blocks.md) | NetworkPolicy blocks traffic; fix it |
| [10-hpa-not-scaling](10-hpa-not-scaling.md) | HPA not scaling; missing metrics-server |
| [11-rollout-stuck](11-rollout-stuck.md) | Rolling update stuck; readiness probe |
| [12-terraform-drift](12-terraform-drift.md) | Terraform drift; detect and reconcile |

**Prerequisites**: Labs 01–02 for cluster and basic GitOps. Argo CD for labs 03–04. CNI with NetworkPolicy (Calico/Cilium) for lab 09.
