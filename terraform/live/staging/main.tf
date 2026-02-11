terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

module "network" {
  source = "../../modules/network"

  resource_group_name = var.resource_group_name
  location            = var.location
  prefix              = var.prefix
  vnet_address_space  = var.vnet_address_space
  aks_subnet_prefix   = var.aks_subnet_prefix
  tags                = var.tags
}

module "acr" {
  source = "../../modules/acr"

  acr_name                = var.acr_name
  resource_group_name     = module.network.resource_group_name
  location                = module.network.resource_group_location
  sku                     = var.acr_sku
  attach_aks_principal_id = module.aks.kubelet_identity[0].object_id
  tags                    = var.tags
}

module "aks" {
  source = "../../modules/aks"

  cluster_name              = var.cluster_name
  location                  = module.network.resource_group_location
  resource_group_name       = module.network.resource_group_name
  dns_prefix               = var.dns_prefix
  subnet_id                 = module.network.aks_subnet_id
  kubernetes_version        = var.kubernetes_version
  system_node_count         = var.system_node_count
  user_node_count           = var.user_node_count
  user_enable_auto_scaling  = var.user_enable_auto_scaling
  user_min_count            = var.user_min_count
  user_max_count            = var.user_max_count
  tags                      = var.tags
}
