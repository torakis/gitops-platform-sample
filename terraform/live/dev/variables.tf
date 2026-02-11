variable "resource_group_name" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "prefix" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "acr_name" {
  type = string
}

variable "vnet_address_space" {
  type    = string
  default = "10.0.0.0/16"
}

variable "aks_subnet_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

variable "acr_sku" {
  type    = string
  default = "Basic"
}

variable "system_node_count" {
  type    = number
  default = 1
}

variable "system_node_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "user_node_count" {
  type    = number
  default = 2
}

variable "user_node_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "user_enable_auto_scaling" {
  type    = bool
  default = true
}

variable "user_min_count" {
  type    = number
  default = 1
}

variable "user_max_count" {
  type    = number
  default = 5
}

variable "tags" {
  type    = map(string)
  default = {}
}
