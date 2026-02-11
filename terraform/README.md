# Terraform - Azure AKS

Provisions Resource Group, VNet, AKS (system + user node pools), ACR (attached to AKS). Optional Key Vault.

## Structure

```
terraform/
├── live/
│   ├── dev/          # Development
│   ├── staging/      # Staging
│   └── prod/         # Production
├── modules/
│   ├── network/      # RG, VNet, subnet
│   ├── aks/          # AKS cluster (system + user node pools)
│   ├── acr/          # Container registry + AKS attach
│   └── keyvault/     # Key Vault (optional)
└── README.md
```

## Prerequisites

- **Azure CLI**: `az login`
- **Terraform**: >= 1.5
- **kubelogin**: For AKS Azure AD auth (recommended)

```bash
# Install kubelogin (macOS)
brew install Azure/kubelogin/kubelogin
```

## Plan and Apply

```bash
cd terraform/live/dev

# Copy and edit tfvars
cp dev.tfvars.example dev.tfvars
# Edit dev.tfvars: acr_name must be globally unique (alphanumeric only)

terraform init
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

## Outputs

After apply:

- **cluster_name** — AKS cluster name
- **acr_login_server** — Registry URL (e.g. `myacr.azurecr.io`)
- **kubeconfig_instructions** — Command to fetch credentials

## Get kubeconfig

```bash
az aks get-credentials --resource-group <rg_name> --name <cluster_name>
```

If using Azure AD auth, convert kubeconfig:

```bash
kubelogin convert-kubeconfig -l azurecli
```

Or use admin credentials:

```bash
az aks get-credentials --resource-group <rg_name> --name <cluster_name> --admin
```

## Destroy Safely

1. **Delete workloads first** — Remove Argo CD apps, deployments, PVCs.
2. **Ensure no dependencies** — External resources referencing this AKS.
3. **Destroy**:

```bash
cd terraform/live/dev
terraform plan -destroy -var-file=dev.tfvars
terraform destroy -var-file=dev.tfvars
```

**Note**: PVCs and LoadBalancer services may leave orphaned disks/load balancers. Clean up in Azure Portal if needed.

## State Backend

**Default**: Local backend (`terraform.tfstate` in each live/* directory).

Add `terraform.tfstate` and `*.tfstate.*` to `.gitignore` (do not commit state).

### Remote Backend (Optional)

Use Azure Storage for shared state:

1. Create a storage account and container:

```bash
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stgitopstfstate"
CONTAINER="tfstate"

az group create -n $RESOURCE_GROUP -l eastus
az storage account create -n $STORAGE_ACCOUNT -g $RESOURCE_GROUP -l eastus --sku Standard_LRS
az storage container create -n $CONTAINER --account-name $STORAGE_ACCOUNT
```

2. Add to `live/dev/main.tf` (replace backend block):

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stgitopstfstate"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

3. Re-run `terraform init` (migrate state when prompted).

## Optional: Key Vault

To add Key Vault, uncomment in `live/dev/main.tf`:

```hcl
data "azurerm_client_config" "current" {}

module "keyvault" {
  source = "../../modules/keyvault"
  
  kv_name             = "kv-${var.prefix}"
  location            = module.network.resource_group_location
  resource_group_name = module.network.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = var.tags
}
```
