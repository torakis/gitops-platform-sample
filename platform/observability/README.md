# Platform Observability

## Components

| Component | Purpose |
|-----------|---------|
| **Prometheus ServiceMonitor** | Scrape metrics from apps (if they expose /metrics) |
| **PrometheusRule** | Alerts for orders-api down, high error rate |
| **Prometheus + Grafana** | Optional stack — see [prometheus-grafana/](prometheus-grafana/) |
| **Metrics** | [metrics-exposed.md](metrics-exposed.md) — what services expose and example queries |

## Manifests

| File | Purpose |
|------|---------|
| `servicemonitor-orders-api.yaml` | Scrape orders-api /metrics in dev/staging/prod |
| `prometheusrule-orders.yaml` | OrdersApiDown, OrdersApiHighErrorRate alerts |
| `prometheus-grafana/` | Helm install + minimal values for kind/k3d |

## Integration

- Requires Prometheus Operator (or Prometheus with scrape configs).
- Optional: Grafana, Loki, Tempo for full observability stack.
- This sample provides **minimal** manifests; you extend per your stack.
