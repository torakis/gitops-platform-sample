# Incident Response Checklist

## 1. Triage

- [ ] Severity: P1 (outage) / P2 (degraded) / P3 (minor)
- [ ] Impact: Who/what is affected?
- [ ] Start timer, create incident channel

## 2. Investigate

- [ ] Check Argo CD sync status (if applicable)
- [ ] `kubectl get pods -n <namespace>` — any Not Ready?
- [ ] `kubectl describe pod <name>` — events
- [ ] `kubectl logs <pod> --previous` — if restarted
- [ ] Check ingress/load balancer

## 3. Mitigate

| Symptom | Action |
|---------|--------|
| Bad deploy | `kubectl rollout undo deployment/<name> -n <ns>` |
| OOM / crash | Increase memory limit or scale |
| Image pull fail | Fix image tag, check ACR/auth |
| DB connection | Check secret, network policy |

## 4. Resolve

- [ ] Confirm fix (smoke test)
- [ ] Close incident
- [ ] Schedule post-mortem if P1/P2

## 5. Follow-up

- [ ] Post-mortem document
- [ ] Update runbooks with learnings
- [ ] Create tickets for preventive work
