# Prometheus + Grafana (Optional)

Self-contained monitoring for kind/k3d. No paid services.

## Install

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-prom-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f platform/observability/prometheus-grafana/values-minimal.yaml
```

## Access

```bash
# Grafana (admin / prom-operator)
kubectl port-forward -n monitoring svc/kube-prom-stack-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/kube-prom-stack-prometheus 9090:9090
```

## Apply Platform Observability

After deploying orders-api and the ServiceMonitor:

```bash
kubectl apply -f platform/observability/servicemonitor-orders-api.yaml
kubectl apply -f platform/observability/prometheusrule-orders.yaml
```

## Dashboards

Use built-in Kubernetes dashboards, or create one for orders-api:

- **Request rate**: `rate(http_requests_received_total{job="orders-api"}[5m])`
- **P95 latency**: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="orders-api"}[5m]))`
- **5xx rate**: `rate(http_requests_received_total{job="orders-api",code=~"5.."}[5m])`

See [metrics-exposed.md](../metrics-exposed.md) for full list.
