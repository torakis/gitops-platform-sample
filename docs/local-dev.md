# Local Development Workflow

Run orders-api and orders-web locally while using the cluster for postgres and other services.

## Prerequisites

- k3d cluster running (`./scripts/k3d-up.sh` executed)
- Dev overlay deployed (`./scripts/bootstrap.sh` + `./scripts/build-images-local.sh`)
- Postgres and orders-db-secret in dev namespace

## Option A: API + Web Locally, Postgres in Cluster

### 1. Port-forward postgres to localhost

```bash
kubectl port-forward svc/postgres -n dev 5432:5432
```

### 2. Run orders-api locally

```bash
cd apps/orders-api
export ConnectionStrings__DefaultConnection="Host=localhost;Port=5432;Database=orders;Username=postgres;Password=postgres"
export ASPNETCORE_ENVIRONMENT=Development
export FeatureFlags__EnableDiscounts=true
dotnet run
```

API runs at http://localhost:5000. Swagger: http://localhost:5000/swagger

### 3. Run orders-web locally (Vite dev server)

```bash
cd apps/orders-web
npm install
npm run dev
```

Vite proxies `/api`, `/healthz`, `/readyz` to `http://localhost:5000` (see `vite.config.ts`). Web runs at http://localhost:5173.

### 4. Verify

```bash
curl -s http://localhost:5000/healthz
# Expected: "Healthy"

curl -s http://localhost:5000/api/orders | head -c 200
# Expected: JSON array (possibly [])
```

Open http://localhost:5173 in browser for the React app.

## Option B: Only API Locally, Web + Postgres in Cluster

### 1. Port-forward postgres (same as above)

```bash
kubectl port-forward svc/postgres -n dev 5432:5432
```

### 2. Run orders-api locally (same as above)

```bash
cd apps/orders-api
export ConnectionStrings__DefaultConnection="Host=localhost;Port=5432;Database=orders;Username=postgres;Password=postgres"
dotnet run
```

### 3. Port-forward orders-web from cluster

```bash
kubectl port-forward svc/orders-web -n dev 3000:80
```

Web at http://localhost:3000. API calls must go to localhost:5000; configure VITE_API_URL or patch the web build to use localhost:5000 for API. The default Vite dev proxy assumes same-origin; for this setup you may need to set `VITE_API_URL=http://localhost:5000` when building the web, or run web locally too (Option A).

## Option C: All Services in Cluster

Use the deployed stack. Add to `/etc/hosts`:

```
127.0.0.1 dev.local
```

Then open http://dev.local. API at http://dev.local/api.

## Windows Notes

- Use `set` instead of `export` for env vars:
  ```cmd
  set ConnectionStrings__DefaultConnection=Host=localhost;Port=5432;Database=orders;Username=postgres;Password=postgres
  dotnet run
  ```
- WSL2: Use `localhost`; Docker Desktop routes correctly.
- PowerShell: `$env:ConnectionStrings__DefaultConnection="Host=localhost;..."`

## Connection String Reference

| Scenario | Value |
|----------|-------|
| Postgres in cluster (port-forward 5432) | `Host=localhost;Port=5432;Database=orders;Username=postgres;Password=postgres` |
| Postgres in cluster (from another pod) | `Host=postgres;Port=5432;Database=orders;Username=postgres;Password=postgres` |
