# Break Me Lab

Deliberate misconfigurations for learners to find and fix.

## How to use

1. Ensure dev overlay works: `kubectl apply -k ../../overlays/dev -n dev`
2. Apply breakme: `kubectl apply -k .`
3. Observe the failure: `kubectl get pods -n breakme`
4. Diagnose: `kubectl describe pod <name> -n breakme`, `kubectl logs`, events
5. Edit the patch file to fix the misconfiguration
6. Re-apply: `kubectl apply -k .`

## Misconfigurations (switch patches in kustomization.yaml)

| File | Issue | Symptom |
|------|-------|---------|
| `bad-probe.yaml` | Readiness path `/nonexistent` | Pods never Ready |
| `bad-secret.yaml` | Secret key typo in deployment ref | CrashLoopBackOff |
| `bad-resources.yaml` | limits < requests | Invalid / CreateContainerConfigError |
