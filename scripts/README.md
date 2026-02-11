# Scripts

## Prerequisites Check

```bash
./scripts/check-prereqs.sh
# or: make check-prereqs
```

Verifies Docker, kubectl, kind or k3d are installed.

## Bootstrap & Apply

```bash
# Build and load images
./scripts/local-registry.sh build
# or: make bootstrap

# Dev (in-cluster postgres)
./scripts/apply-dev.sh
# or: make deploy-dev

# Staging (create secret first)
kubectl create secret generic orders-db-secret \
  --from-literal=connection-string='Host=YOUR_DB;Port=5432;Database=orders;Username=user;Password=pass' \
  -n staging
./scripts/apply-staging.sh

# Prod (create secret first — same pattern as staging)
./scripts/apply-prod.sh
```

## Port-Forward Helpers

```bash
./scripts/port-forward.sh
# Prints commands for Argo CD, orders-api, Prometheus port-forwards
```

## Local Hosts

```bash
./scripts/generate-local-hosts.sh
# or: make print-hosts
# Outputs /etc/hosts entry: 127.0.0.1 dev.local
# Concrete add command: echo '127.0.0.1 dev.local' | sudo tee -a /etc/hosts
```
