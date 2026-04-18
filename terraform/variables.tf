variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "bestbuy-store-rg"
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "canadacentral"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "bestbuy-aks"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID"
  default     = "optional-fallback-value"
}