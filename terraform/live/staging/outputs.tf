output "cluster_name"          { value = module.aks.cluster_name }
output "resource_group_name"   { value = module.network.resource_group_name }
output "acr_login_server"      { value = module.acr.login_server }
output "acr_name"              { value = module.acr.acr_name }
output "kubeconfig_instructions" {
  value = "az aks get-credentials --resource-group ${module.network.resource_group_name} --name ${module.aks.cluster_name}"
}
