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

variable "system_node_vm_size" {
  type        = string
  description = "VM size for the system node pool"
  default     = "Standard_D4s_v3"
}

variable "system_node_min_count" {
  type        = number
  description = "Minimum number of nodes in the system pool"
  default     = 2
}

variable "system_node_max_count" {
  type        = number
  description = "Maximum number of nodes in the system pool"
  default     = 3
}

variable "user_node_vm_size" {
  type        = string
  description = "VM size for the user node pool"
  default     = "Standard_DS3_v2"
}

variable "user_node_min_count" {
  type        = number
  description = "Minimum number of nodes in the user pool"
  default     = 1
}

variable "user_node_max_count" {
  type        = number
  description = "Maximum number of nodes in the user pool"
  default     = 3
}

variable "enable_system_pool_taint" {
  type        = bool
  description = "Whether to taint the system node pool with CriticalAddonsOnly=true:NoSchedule"
  default     = false
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

variable "local_account_disabled" {
  type        = bool
  description = "Disable local accounts for the AKS cluster"
  default     = false
}
