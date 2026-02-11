# Lab 12: Terraform Drift — Detect and Reconcile

Change infrastructure manually; detect drift with `terraform plan`; reconcile with `terraform apply`.

## Goal

- Apply Terraform to create a resource
- Manually change the resource outside Terraform
- Run `terraform plan` to see drift
- Run `terraform apply` to reconcile

## Prerequisites

- Terraform >= 1.5
- This lab uses `local_file` so it works **without any cloud provider** (no AWS/Azure/GCP)

## Steps

### 1. Use the drift-demo directory

```bash
cd docs/labs/terraform-drift-demo
```

The repo includes `main.tf` with a `local_file` resource (no cloud provider required).

### 2. Initialize and apply

```bash
terraform init
terraform apply -auto-approve
```

**Expected output**:

```
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

```bash
cat config.txt
```

**Expected**:

```
version: 1.0
managed-by: terraform
```

### 4. Introduce drift (manual change)

Edit the file outside Terraform:

```bash
echo "version: 2.0 - I changed this manually" > config.txt
cat config.txt
```

**Expected**:

```
version: 2.0 - I changed this manually
```

### 5. Detect drift

```bash
terraform plan
```

**Expected output**:

```
local_file.config: Refreshing state...
local_file.config: Plan: 0 to add, 1 to change, 0 to destroy.
...
~ content = "version: 1.0\nmanaged-by: terraform" -> "version: 2.0 - I changed this manually"
...
Plan: 0 to add, 1 to change, 0 to destroy.
```

Terraform detected that the file content no longer matches desired state.

### 6. Reconcile

```bash
terraform apply -auto-approve
```

**Expected output**:

```
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

```bash
cat config.txt
```

**Expected** (restored to Terraform state):

```
version: 1.0
managed-by: terraform
```

### 7. Cleanup

```bash
terraform destroy -auto-approve
cd ../../..  # back to repo root
```

---

## With Real Infrastructure (e.g. Azure)

The same pattern applies to cloud resources:

1. `terraform apply` creates an AKS cluster, ACR, etc.
2. Someone changes a tag, node count, or SKU in the Azure portal (or CLI).
3. `terraform plan` shows drift: "Module.aks will be updated in-place..."
4. `terraform apply` reconciles the resource to match the Terraform config.

Example drift in Azure:

```bash
# After manual change in portal (e.g. add a tag)
terraform plan
# Output: ~ tags = { "env" = "dev" } -> { "env" = "dev", "modified" = "by-hand" }
terraform apply -auto-approve
# Tags reverted to Terraform-defined state
```

---

## Why It Happened

- Terraform stores desired state in `.tf` files and current state in `terraform.tfstate`. When you change infrastructure outside Terraform, the real world diverges from state.
- `terraform plan` refreshes state from the real world and compares to the config; any difference is "drift."
- `terraform apply` updates the real world to match the config (and state).

## How to Prevent Drift in a Platform

- **Enforce Terraform for changes**: Restrict console/portal access; all infra changes via MRs and Terraform.
- **Automated drift detection**: Run `terraform plan` in CI on a schedule; fail or alert if non-empty plan.
- **Remote state + locking**: Use S3/Azure Storage backend with DynamoDB/state lock to prevent concurrent applies.
- **Policy**: OPA/Sentinel or Terraform Cloud to restrict who can apply and what resources can be created.
