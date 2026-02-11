resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false
  tags                = var.tags
}

# Attach ACR to AKS: grant AKS managed identity pull permission
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.attach_aks_principal_id != null ? 1 : 0
  principal_id         = var.attach_aks_principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}
