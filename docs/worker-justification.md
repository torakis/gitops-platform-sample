# Worker Service: .NET vs Node.js

## Choice: .NET 8 Worker

The worker service is implemented in .NET 8 using `BackgroundService`.

## Rationale

1. **Ecosystem consistency**: Same stack as orders-api; shared PostgreSQL, similar tooling, and Docker base images.
2. **Built-in `BackgroundService`**: Native support for long-running background work with clean startup/shutdown and DI.
3. **Shared data model**: Can reuse the same DbContext/entity definitions if placed in a shared lib, or keep a minimal copy for loose coupling.
4. **Operational alignment**: Same health check patterns, logging (Serilog/NLog), and Kubernetes probe conventions as the API.
5. **Skills transfer**: Developers already working on orders-api can contribute to the worker without context switching.

## Node.js Alternative

Node.js would be appropriate if:
- The team is primarily JavaScript/TypeScript.
- The workload is I/O-heavy with many external HTTP/queue calls (Node's event loop excels here).
- You prefer Bull/BullMQ, Agenda, or similar job queues with Redis.

For this sample, the worker performs simple DB polling (Pending → Processing). .NET's `BackgroundService` is a natural fit and keeps the mono-repo cohesive.
