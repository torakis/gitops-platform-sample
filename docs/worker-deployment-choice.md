# Worker: Deployment vs Job/CronJob

## Choice: **Deployment-based worker**

We use a Deployment (long-running pod) that continuously polls for new orders and marks them processed.

## Rationale

| Criterion | Deployment | Job / CronJob |
|-----------|------------|---------------|
| **Workload** | Continuous stream (orders arrive anytime) | Batch, time-bound |
| **Latency** | Low (polls every 10s) | Higher (CronJob runs on schedule) |
| **Simplicity** | Single pod, always running | Multiple pods, completion semantics |
| **Resource use** | Steady (1 pod) | Spike per run |

### When to use Jobs/CronJobs

- **CronJob**: Nightly reports, cleanup, backups, scheduled sync
- **Job**: One-off migration, batch import, run-to-completion

### When to use Deployment

- **Deployment**: Message/queue consumers, polling workers, real-time processors

Our worker processes orders as they arrive. There is no natural "batch end" — work is continuous. A CronJob would introduce unnecessary delay (e.g. only run every minute) and complicate retry logic. A Deployment keeps one process always ready to pick up work.

### Alternative: Queue-based

For production at scale, a queue (RabbitMQ, Azure Service Bus, etc.) with a consumer Deployment is preferred. This sample uses DB polling for simplicity and to avoid extra infrastructure.
