variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "MG_RG"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "westeurope"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "memgraph-ha"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 5
}

variable "node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_A2_v2"
}

variable "values_file" {
  description = "Helm values file name (relative to the aks/ directory)"
  type        = string
  default     = "values-aks.yaml"
}
