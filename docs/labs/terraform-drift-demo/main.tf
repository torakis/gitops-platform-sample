# Terraform drift demo - no cloud provider required
# Usage: terraform init && terraform apply -auto-approve
# Then manually edit config.txt, run terraform plan to see drift, terraform apply to reconcile.
terraform {
  required_version = ">= 1.5"
}

resource "local_file" "config" {
  content  = "version: 1.0\nmanaged-by: terraform"
  filename = "${path.module}/config.txt"
}
