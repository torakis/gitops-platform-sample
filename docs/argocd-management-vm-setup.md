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

## Part 4: Expose Argo CD on Port 8080 (Nginx Reverse Proxy)

Argo CD with `--insecure` serves HTTP on port 80. Nginx proxies to the HTTP NodePort.

1. Get the Argo CD HTTP NodePort:

```bash
kubectl get svc argocd-server -n argocd
```

Note the NodePort for port 80 (e.g. `80:30080/TCP,443:30443/TCP` → use **30080**).

2. Install Nginx:

```bash
sudo apt update
sudo apt install -y nginx
```

3. Create Nginx config (replace `30080` with your NodePort for port 80 from step 1):

```bash
sudo tee /etc/nginx/sites-available/argocd <<'EOF'
server {
    listen 8080;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:30080;
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

4. Enable and restart:

```bash
sudo ln -sf /etc/nginx/sites-available/argocd /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx
```

5. Open firewall:

```bash
sudo ufw allow 8080/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

6. Access: **http://\<VM-IP\>:8080/** (use HTTP, not HTTPS). Example: **http://192.168.174.250:8080/**

---

## Part 5: Quick Reference

| Task | Command |
|------|---------|
| Get Argo CD password | `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' \| base64 -d` |
| Get NodePorts | `kubectl get svc argocd-server -n argocd` (use port 80 NodePort, e.g. 30080) |
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

- Use **http://** not https:// (Nginx serves plain HTTP on 8080).
- Confirm NodePort: `kubectl get svc argocd-server -n argocd`. Use the port 80 NodePort (e.g. 30080) in `proxy_pass`, not 443.
- Check firewall: `sudo ufw allow 8080/tcp`.
