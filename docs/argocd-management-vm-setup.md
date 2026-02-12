# Argo CD Management VM Setup Guide

Complete guide: Ubuntu VM → k3s → Argo CD → GitOps repo → internet access.

---

## Part 1: VM Prerequisites

- Ubuntu 22.04 or 24.04 LTS
- SSH access
- Minimum: 2 vCPU, 4 GB RAM (2 vCPU, 8 GB recommended)

---

## Part 2: Install on the VM

SSH into your VM and run these steps.

### 2.1 Update system

```bash
sudo apt update && sudo apt upgrade -y
```

### 2.2 Install k3s

```bash
curl -sfL https://get.k3s.io | sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

Add kubectl to your user (optional):

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
export KUBECONFIG=~/.kube/config
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
```

Verify:

```bash
kubectl get nodes
# Should show: Ready
```

### 2.3 Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 2.4 Install Argo CD

```bash
# Add Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create namespace
kubectl create namespace argocd

# Install Argo CD (NodePort for external access)
helm upgrade --install argocd argo/argo-cd -n argocd \
  --set server.service.type=NodePort \
  --set server.extraArgs[0]=--insecure \
  --set configs.params.server.insecure=true

# Wait for ready
kubectl wait -n argocd --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=180s
```

Get admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
echo
```

Get NodePort (default usually 30000–32767):

```bash
kubectl get svc argocd-server -n argocd
# Note the NodePort for port 443 (e.g. 30443)
```

Access locally: `https://<VM-IP>:<NodePort>` (accept self-signed cert)

### 2.5 Install Argo CD CLI (optional, on VM or your laptop)

```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

---

## Part 3: Create the GitOps Repository

Create a new GitHub repo (e.g. `your-org/gitops-platform`). This repo holds Argo CD Applications and deploy manifests for all your app repos.

### 3.1 Repo Structure

```
gitops-platform/
├── README.md
├── argocd/
│   ├── root-app.yaml             # Bootstrap: apply this once manually
│   ├── projects/
│   │   └── default.yaml
│   └── applications/
│       ├── platform-bootstrap.yaml   # Creates namespaces first
│       ├── client-a-staging.yaml
│       ├── client-a-prod.yaml
│       ├── client-b-staging.yaml
│       ├── client-b-prod.yaml
│       └── client-c-staging.yaml
├── deploy/
│   ├── client-a/
│   │   ├── staging/
│   │   │   └── kustomization.yaml
│   │   └── prod/
│   │       └── kustomization.yaml
│   ├── client-b/
│   │   └── ...
│   └── client-c/
│       └── ...
└── platform/
    └── environments/
        ├── kustomization.yaml
        ├── namespace-staging.yaml
        └── namespace-prod.yaml
```

### 3.2 File Contents

**`argocd/projects/default.yaml`**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default
  namespace: argocd
spec:
  description: Default project for all applications
  sourceRepos:
  - '*'
  destinations:
  - namespace: '*'
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: ''
    kind: '*'
```

**`argocd/root-app.yaml`** (bootstrap – apply this once manually)

Replace `YOUR_GITHUB_ORG` and `gitops-platform` with your repo. This app points to `argocd/applications`, so Argo CD will create an Application for each YAML file in that folder.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_GITHUB_ORG/gitops-platform.git
    path: argocd/applications
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**`argocd/applications/client-a-staging.yaml`**

Replace repo URL and path for each client. Each Application can point to a different repo.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: client-a-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_ORG/client-a-app.git
    path: deploy/overlays/staging
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: client-a-staging
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**`argocd/applications/platform-bootstrap.yaml`** (creates namespaces – syncs first)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform-bootstrap
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_GITHUB_ORG/gitops-platform.git
    path: platform/environments
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

(Repeat `client-a-staging.yaml` pattern for `client-a-prod`, `client-b-staging`, etc., adjusting repo/path/namespace.)

**`platform/environments/kustomization.yaml`**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespace-client-a-staging.yaml
  - namespace-client-a-prod.yaml
  - namespace-client-b-staging.yaml
  - namespace-client-b-prod.yaml
  - namespace-client-c-staging.yaml
  - namespace-client-c-prod.yaml
```

**`platform/environments/namespace-client-a-staging.yaml`** (example; create one per destination namespace)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: client-a-staging
```

Add similar files for `client-a-prod`, `client-b-staging`, etc. Names must match the `destination.namespace` in each Application.

### 3.3 Add Repository Credentials (private repos)

If your app repos are private, configure credentials in Argo CD:

```bash
# Via UI: Settings → Repositories → Connect Repo
# Or via CLI:
argocd repo add https://github.com/YOUR_ORG/private-repo.git \
  --username YOUR_GITHUB_USER \
  --password YOUR_PERSONAL_ACCESS_TOKEN
```

For SSH:

```bash
argocd repo add git@github.com:YOUR_ORG/private-repo.git \
  --ssh-private-key-path ~/.ssh/id_rsa
```

### 3.4 Bootstrap Argo CD from the VM

After pushing the GitOps repo, apply the root app once:

```bash
# Option A: Apply from cloned repo
git clone https://github.com/YOUR_GITHUB_ORG/gitops-platform.git
cd gitops-platform
kubectl apply -f argocd/root-app.yaml -n argocd

# Option B: Apply directly (replace URLs)
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_GITHUB_ORG/gitops-platform.git
    path: argocd/applications
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

Argo CD will create Applications for each file in `argocd/applications/` (client-a-staging, client-a-prod, etc.).

---

## Part 4: Expose Argo CD to the Internet

### Option A: Firewall + NodePort (simplest)

1. Open the NodePort (e.g. 30443) in your firewall or cloud security group.

**UFW (Ubuntu):**

```bash
sudo ufw allow 30443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

**Cloud (e.g. AWS, GCP, Azure):**  
Open TCP port 30443 in the VM’s security group / firewall rules.

2. Access: `https://<VM-PUBLIC-IP>:30443`  
Accept the self-signed certificate.

### Option B: Nginx Reverse Proxy + TLS (recommended for production)

Requires a domain (e.g. `argocd.yourdomain.com`) pointing to your VM.

1. Install Nginx and Certbot:

```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

2. Create Nginx config:

```bash
sudo tee /etc/nginx/sites-available/argocd <<'EOF'
server {
    listen 80;
    server_name argocd.yourdomain.com;
    location / {
        proxy_pass https://127.0.0.1:30443;
        proxy_ssl_verify off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
```

Replace `argocd.yourdomain.com` with your domain. Replace `30443` with the NodePort from `kubectl get svc argocd-server -n argocd`.

3. Enable and get TLS:

```bash
sudo ln -s /etc/nginx/sites-available/argocd /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d argocd.yourdomain.com
```

4. Access: `https://argocd.yourdomain.com`

### Option C: Cloudflare Tunnel (no open ports)

If you use Cloudflare:

1. Install cloudflared on the VM.
2. Create a tunnel and route `argocd.yourdomain.com` to `https://localhost:30443`.
3. No firewall changes needed; traffic enters via Cloudflare.

---

## Part 5: Quick Reference

| Task | Command |
|------|---------|
| Get Argo CD password | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' \| base64 -d` |
| Get NodePort | `kubectl get svc argocd-server -n argocd` |
| List applications | `argocd app list` (or Argo CD UI) |
| Sync app | `argocd app sync client-a-staging` |
| Restart Argo CD server | `kubectl rollout restart deployment argocd-server -n argocd` |

---

## Part 6: Checklist

- [ ] Ubuntu VM with SSH
- [ ] k3s installed and node Ready
- [ ] Argo CD installed via Helm
- [ ] GitOps repo created with Applications
- [ ] Bootstrap Application applied
- [ ] Repo credentials added (if private)
- [ ] Firewall/security group opened or reverse proxy configured
- [ ] Argo CD UI accessible from internet

---

## Troubleshooting

**Argo CD can't reach GitHub**

- For private repos: add repo credentials (Part 3.3).
- Ensure VM has outbound internet (ports 443, 9418 for Git).

**Sync fails with "manifest generation error"**

- Check that `path` in the Application matches your repo layout.
- Verify `targetRevision` exists (branch or tag).

**Can't access UI**

- Confirm NodePort with `kubectl get svc argocd-server -n argocd`.
- Check firewall/security group.
- If using Nginx: ensure `proxy_pass` uses correct NodePort.
