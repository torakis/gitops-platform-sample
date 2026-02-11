# gitops-platform-sample — Repository Structure

```
gitops-platform-sample/
├── .github/
│   └── workflows/
│       ├── dotnet-build.yml          # .NET build/test
│       ├── react-build.yml           # React build/test
│       ├── build-push-images.yml     # Container build & push
│       └── gitops-update.yml         # Update Kustomize image tags (GitOps-style)
├── apps/
│   ├── orders-api/                   # .NET 8 Web API
│   │   ├── src/
│   │   │   └── OrdersApi/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── OrdersApi.csproj
│   ├── orders-web/                   # React (Vite + TypeScript)
│   │   ├── src/
│   │   ├── public/
│   │   ├── Dockerfile
│   │   └── package.json
│   └── worker/                       # .NET background worker
│       ├── src/
│       ├── tests/
│       ├── Dockerfile
│       └── Worker.csproj
├── platform/                         # Platform team definitions
│   ├── environments/
│   ├── policies/
│   ├── observability/
│   └── deployment-patterns/
├── argocd/                           # Argo CD (install, projects, app-of-apps)
│   ├── install/                      # Helm values (kind, AKS)
│   ├── projects/                     # AppProjects
│   └── applications/                 # root, platform-app, apps-app
├── deploy/                           # GitOps manifests
│   ├── base/                         # Kustomize bases
│   │   ├── orders-api/
│   │   ├── orders-web/
│   │   ├── worker/
│   │   └── postgres/
│   ├── overlays/
│   │   ├── dev/         # kind/nginx
│   │   ├── dev-k3d/     # k3d/Traefik (local default)
│   │   ├── staging/
│   │   └── prod/
│   └── argo/                         # ArgoCD app-of-apps
│       ├── bootstrap/                # Platform components
│       └── applications/             # Business services
├── terraform/                        # Infrastructure as Code
│   ├── modules/
│   │   ├── aks/
│   │   ├── networking/
│   │   ├── acr/
│   │   └── key-vault/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── scripts/                          # Local dev & bootstrap
│   ├── k3d-up.sh
│   ├── argocd-install.sh
│   ├── bootstrap.sh
│   ├── build-images-local.sh
│   ├── apply-dev-k3d.sh
│   ├── port-forward.sh
│   └── dev-loop.sh
├── templates/                        # Golden path service templates
│   └── service-template/
├── portal/                           # Minimal IDP (docs + templates)
│   └── catalog/
├── docs/                             # Documentation
│   ├── STRUCTURE.md
│   ├── how-it-works.md
│   ├── local-deploy-gitops.md
│   ├── local-dev.md
│   ├── troubleshooting-local.md
│   ├── learning-path.md
│   ├── labs/
│   ├── runbooks/
│   └── cka-drills/
├── .gitignore
├── README.md
└── docker-compose.yml                # Local dev (optional)
```

## Module Purposes

| Path | Purpose |
|------|---------|
| `apps/` | Application source code (orders-api, orders-web, worker) |
| `platform/` | Platform team definitions: envs, policies, observability, patterns |
| `deploy/` | Kustomize bases + overlays; ArgoCD app-of-apps |
| `terraform/` | Azure AKS, networking, ACR, optional Key Vault |
| `scripts/` | kind/k3d bootstrap, local registry |
| `templates/` | Golden path service template for new services |
| `portal/` | Minimal IDP catalog (docs + templates, no Backstage required) |
| `docs/` | Learning path, labs, runbooks, CKA-style drills |
