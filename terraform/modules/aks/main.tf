resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  # System node pool (hosts system pods; keep small)
  default_node_pool {
    name                = "system"
    vm_size             = var.system_node_vm_size
    vnet_subnet_id      = var.subnet_id
    node_count          = var.system_node_count
    enable_auto_scaling = false

    # Required for non-system workloads; system pods prefer this pool
    orchestrator_version = var.kubernetes_version
    tags                 = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = var.tags
}

# User node pool for workloads
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_vm_size
  node_count            = var.user_node_count
  enable_auto_scaling   = var.user_enable_auto_scaling
  min_count             = var.user_min_count
  max_count             = var.user_max_count

  tags = var.tags
}
