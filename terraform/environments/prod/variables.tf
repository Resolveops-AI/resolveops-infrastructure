variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment label (e.g., quickhaul)"
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
  description = "Name of the resource group for the QuickHaul cluster"
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

# ACR is shared between both clusters. The prod (quickhaul) environment reads
# the existing ACR via data source rather than managing it.
variable "acr_name" {
  type        = string
  description = "Name of the shared Azure Container Registry (managed by the resolveops environment)"
}

variable "acr_resource_group_name" {
  type        = string
  description = "Resource group where the shared ACR resides (the resolveops resource group)"
}

# Cluster 2: QuickHaul AKS
variable "quickhaul_aks_name" {
  type        = string
  description = "Name of the QuickHaul AKS cluster"
  default     = "quickhaul-aks"
}

variable "key_vault_name" {
  type        = string
  description = "Key Vault name for QuickHaul secrets"
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
  description = "Workload identity name for QuickHaul services"
}

variable "workload_identity_service_account" {
  type        = string
  description = "Service account name for Workload Identity"
}

# QuickHaul needs dev/prod namespace separation so that Argo CD can manage
# two independent GitOps environments from one cluster.
variable "quickhaul_dev_namespace" {
  type        = string
  description = "Kubernetes namespace for QuickHaul dev environment"
  default     = "quickhaul-dev"
}

variable "quickhaul_prod_namespace" {
  type        = string
  description = "Kubernetes namespace for QuickHaul prod environment"
  default     = "quickhaul-prod"
}

# Argo CD namespace — bootstrapped by Terraform, populated by Helm.
variable "argocd_namespace" {
  type        = string
  description = "Kubernetes namespace for Argo CD (GitOps controller)"
  default     = "argocd"
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
