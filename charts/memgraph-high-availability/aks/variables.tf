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

variable "release_namespace" {
  description = "Kubernetes namespace for the Helm release and license secret"
  type        = string
  default     = "default"
}

variable "secret_name" {
  description = "Name of the Kubernetes secret holding the Memgraph enterprise license. Must match secrets.name in the chart values."
  type        = string
  default     = "memgraph-secrets"
}

variable "memgraph_enterprise_license" {
  description = "Memgraph enterprise license key"
  type        = string
  sensitive   = true
}

variable "memgraph_organization_name" {
  description = "Memgraph organization name associated with the enterprise license"
  type        = string
  sensitive   = true
}
