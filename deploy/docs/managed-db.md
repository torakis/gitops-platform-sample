# Managed Database (Staging/Prod)

Staging and prod overlays do **not** include in-cluster Postgres. Use a managed PostgreSQL (Azure Database for PostgreSQL, AWS RDS, etc.).

## Create the Secret

```bash
kubectl create secret generic orders-db-secret \
  --from-literal=connection-string='Host=your-server.postgres.database.azure.com;Port=5432;Database=orders;Username=user@server;Password=xxx;SSL Mode=Require' \
  -n staging
```

## Connection String Format

- **Azure**: `Host=SERVER.postgres.database.azure.com;Port=5432;Database=orders;Username=USER@SERVER;Password=XXX;SSL Mode=Require`
- **AWS RDS**: `Host=xxx.region.rds.amazonaws.com;Port=5432;Database=orders;Username=user;Password=xxx`

## Sealed Secrets (Optional)

To store encrypted secrets in Git:

1. Install [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
2. Create sealed secret: `kubeseal --format yaml < secret.yaml > sealed-secret.yaml`
3. Add sealed-secret to overlay resources

Default: plain Secret for learning; use external secret store in production.
