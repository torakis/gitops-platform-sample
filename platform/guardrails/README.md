# Platform Guardrails

Default policies and standards for workloads and operations.

## Contents

| Document | Purpose |
|----------|---------|
| [baseline-resource-policy.md](baseline-resource-policy.md) | Required resource limits, probes, image rules |
| [namespace-conventions.md](namespace-conventions.md) | Namespace naming and labels |
| [labels-annotations.md](labels-annotations.md) | Standard labels and annotations |
| [kyverno-policies.yaml](kyverno-policies.yaml) | Example Kyverno policies (audit mode) |
| [runbooks/](runbooks/) | Oncall basics, incident response checklist |

## Kyverno (Optional)

Works with kind/k3d. Install Kyverno, then apply policies:

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
kubectl apply -f platform/guardrails/kyverno-policies.yaml
```

Policies run in **Audit** mode by default. Change `validationFailureAction: Enforce` to block non-compliant resources.
