variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., resolveops)"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "owner" {
  type        = string
  description = "Owner tag value"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for the ResolveOps platform cluster"
}

variable "vnet_name" {
  type        = string
  description = "Virtual network name"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for VNet"
}

variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  description = "Map of subnets"
}

variable "acr_name" {
  type        = string
  description = "ACR name (shared by both clusters)"
}

# Renamed from aks_cluster_name to make the purpose explicit.
variable "resolveops_aks_name" {
  type        = string
  description = "Name of the ResolveOps AKS cluster"
  default     = "resolveops-aks"
}

variable "key_vault_name" {
  type        = string
  description = "Key Vault name for ResolveOps platform secrets"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Log Analytics workspace name"
}

variable "workload_identity_name" {
  type        = string
  description = "Workload identity name for ResolveOps platform services"
}

# The single namespace where all ResolveOps platform microservices run.
# ResolveOps does not need dev/prod namespace separation — it IS the monitoring platform.
variable "resolveops_namespace" {
  type        = string
  description = "Kubernetes namespace for ResolveOps platform microservices"
  default     = "resolveops"
}

variable "workload_identity_service_account" {
  type        = string
  description = "Service account for Workload Identity"
}

variable "enable_service_bus" {
  type        = bool
  description = "Enable Service Bus"
  default     = false
}

variable "enable_private_aks" {
  type        = bool
  description = "Enable private AKS"
  default     = false
}

variable "enable_private_endpoints" {
  type        = bool
  description = "Enable private endpoints"
  default     = false
}

variable "enable_app_gateway" {
  type        = bool
  description = "Enable Application Gateway"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = {}
}
