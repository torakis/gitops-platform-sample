# Platform Policies

Policies define security, networking, and resource behavior.

## Contents

- **NetworkPolicy** — Restrict pod-to-pod and ingress/egress traffic
- **RBAC** — ServiceAccount, Role, RoleBinding examples
- **Pod Security** — (Optional) Pod Security Standards / Admission

## Applying Policies

Policies are applied per-namespace via Kustomize or Argo CD. The bootstrap app includes these for each environment.
