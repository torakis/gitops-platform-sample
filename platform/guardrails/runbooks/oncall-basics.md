# Oncall Basics

## Before Oncall

- [ ] Access to cluster: `kubectl` configured, `az aks get-credentials` for AKS
- [ ] Argo CD URL and credentials (if used)
- [ ] Runbook links: broken-pod, dns, rbac, failed-rollout
- [ ] Escalation path documented

## During Incident

1. **Acknowledge** — Confirm you're investigating
2. **Assess** — Scope (one app? whole cluster? one env?)
3. **Diagnose** — `kubectl get pods`, `describe`, `logs`, events
4. **Mitigate** — Rollback, scale, restart per runbook
5. **Communicate** — Update status page / Slack
6. **Post-incident** — Blameless review, update runbooks

## Quick Commands

```bash
kubectl get pods -A | grep -v Running
kubectl get events -A --sort-by='.lastTimestamp' | tail -20
kubectl logs deployment/orders-api -n dev --tail=100
```

## Runbooks

- [Broken Pod](../../../docs/runbooks/broken-pod.md)
- [DNS Issue](../../../docs/runbooks/dns-issue.md)
- [RBAC Denied](../../../docs/runbooks/rbac-denied.md)
- [Failed Rollout](../../../docs/runbooks/failed-rollout.md)
- [Incident Response Checklist](./incident-response-checklist.md)
