variable "cluster_name" {
  type        = string
  description = "Name of the AKS cluster"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to use"
  default     = "1.34"
}

variable "vnet_subnet_id" {
  type        = string
  description = "Subnet ID for the default node pool"
}

variable "node_vm_size" {
  type        = string
  description = "VM size for the default node pool"
  default     = "Standard_B2ms"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the default pool"
  default     = 2
}

variable "private_cluster_enabled" {
  type        = bool
  description = "Enable private cluster"
  default     = true
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for AKS monitoring"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the AKS resources"
  default     = {}
}
