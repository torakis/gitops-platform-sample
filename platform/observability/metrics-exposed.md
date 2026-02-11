# Metrics Exposed by Platform Services

## Overview

Services in this sample expose Prometheus metrics at `/metrics`. Use these for dashboards, SLOs, and alerts.

## orders-api

**Library**: `prometheus-net.AspNetCore`  
**Endpoint**: `GET /metrics` (port 5000)

| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_received_total` | Counter | Total HTTP requests by method, code |
| `http_request_duration_seconds` | Histogram | Request duration |
| `dotnet_gc_*` | Gauges | .NET GC metrics |
| `dotnet_total_memory_bytes` | Gauge | Managed heap size |
| `process_*` | Various | Process CPU, memory |

### Example Queries

```
# Request rate (req/s)
rate(http_requests_received_total{job="orders-api"}[5m])

# P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="orders-api"}[5m]))

# 5xx error rate
rate(http_requests_received_total{job="orders-api",code=~"5.."}[5m])
```

## service-template (MyService)

Same library as orders-api. Endpoints: `/healthz`, `/readyz`, `/api/hello`, `/metrics`.

| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_received_total` | Counter | Total requests |
| `http_request_duration_seconds` | Histogram | Latency |
| `dotnet_*` | Various | .NET runtime |

## ServiceMonitor

`platform/observability/servicemonitor-orders-api.yaml` configures Prometheus Operator to scrape `orders-api` in dev, staging, prod. Ensure the `app: orders-api` label exists on the Service.
