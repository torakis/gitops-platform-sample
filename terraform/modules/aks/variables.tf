variable "cluster_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.28"
}

# System node pool
variable "system_node_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "system_node_count" {
  type    = number
  default = 1
}

# User node pool
variable "user_node_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "user_node_count" {
  type    = number
  default = 2
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
