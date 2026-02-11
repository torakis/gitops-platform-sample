variable "acr_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku" {
  type    = string
  default = "Basic"
}

# AKS managed identity principal ID for AcrPull role
variable "attach_aks_principal_id" {
  type        = string
  default     = null
  description = "AKS kubelet identity principal ID to grant ACR pull"
}

variable "tags" {
  type    = map(string)
  default = {}
}
