# orders-api Prometheus Metrics

## Library

We use **prometheus-net.AspNetCore** (NuGet: `prometheus-net.AspNetCore`).

- **Docs**: https://github.com/prometheus-net/prometheus-net
- **Endpoint**: `GET /metrics`

## Default Metrics

The library automatically exposes:

| Metric | Description |
|--------|-------------|
| `http_requests_received_total` | Total HTTP requests (counter) |
| `http_request_duration_seconds` | Request duration histogram |
| `dotnet_*` | .NET runtime metrics (GC, threads, etc.) |

## Usage in Kubernetes

1. Annotate the Service or Pod for Prometheus scrape:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "5000"
    prometheus.io/path: "/metrics"
```

2. Or use a ServiceMonitor (Prometheus Operator) — see `platform/observability/servicemonitor-orders-api.yaml`.

## Excluding Health Endpoints

The `prometheus-net` library captures all HTTP requests by default. To reduce cardinality from health probes, add this in `Program.cs`:

```csharp
builder.Services.AddHttpMetrics(options =>
{
    options.RequestCount.ExcludePaths = new[] { "/healthz", "/readyz", "/metrics" };
    options.RequestDuration.ExcludePaths = new[] { "/healthz", "/readyz", "/metrics" };
});
```

See [prometheus-net HttpMiddlewareExporterOptions](https://github.com/prometheus-net/prometheus-net#http-request-tracking) for full options.
