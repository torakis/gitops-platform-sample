output "cluster_name" {
  value       = module.aks.cluster_name
  description = "AKS cluster name"
}

output "resource_group_name" {
  value       = module.network.resource_group_name
  description = "Resource group name"
}

output "acr_login_server" {
  value       = module.acr.login_server
  description = "ACR login server (e.g. myacr.azurecr.io)"
}

output "acr_name" {
  value       = module.acr.acr_name
  description = "ACR registry name"
}

output "kubeconfig_instructions" {
  value       = <<-EOT

    Get credentials:
      az aks get-credentials --resource-group ${module.network.resource_group_name} --name ${module.aks.cluster_name}

    AKS uses Azure AD auth by default. Install kubelogin if needed:
      kubelogin convert-kubeconfig -l azurecli

    Or use --admin to get admin kubeconfig:
      az aks get-credentials --resource-group ${module.network.resource_group_name} --name ${module.aks.cluster_name} --admin

  EOT
  description = "Instructions to obtain kubeconfig"
}
