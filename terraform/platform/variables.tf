# Variable declarations for the ResolveOps platform infrastructure
variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for all platform resources"
}

variable "vnet_name" {
  type        = string
  description = "Virtual network name"
  default     = "vnet-resolveops-platform-01"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the VNet"
  default     = ["172.16.0.0/16"]
}

variable "subnets" {
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string))
  }))
  description = "Subnets map — must include 'resolveops-aks' and 'quickhaul-aks'"
  default = {
    "resolveops-aks" = { address_prefixes = ["172.16.1.0/24"], service_endpoints = ["Microsoft.KeyVault"] }
    "quickhaul-aks"  = { address_prefixes = ["172.16.2.0/24"], service_endpoints = ["Microsoft.KeyVault"] }
  }
}

variable "acr_name" {
  type        = string
  description = "Azure Container Registry name (must be globally unique)"
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Log Analytics workspace name"
  default     = "law-resolveops-platform-01"
}

variable "key_vault_name" {
  type        = string
  description = "Key Vault name for ResolveOps platform secrets"
}

# ResolveOps runs on one cluster with one namespace — no dev/prod split needed
variable "resolveops_aks_name" {
  type        = string
  description = "Name of the ResolveOps AKS cluster"
  default     = "resolveops-aks"
}

variable "resolveops_namespace" {
  type        = string
  description = "Kubernetes namespace for ResolveOps services"
  default     = "resolveops"
}

# QuickHaul runs on its own cluster with dev and prod namespaces
variable "quickhaul_aks_name" {
  type        = string
  description = "Name of the QuickHaul AKS cluster"
  default     = "quickhaul-aks"
}

variable "quickhaul_dev_namespace" {
  type        = string
  description = "QuickHaul dev namespace"
  default     = "quickhaul-dev"
}

variable "quickhaul_prod_namespace" {
  type        = string
  description = "QuickHaul prod namespace"
  default     = "quickhaul-prod"
}

variable "argocd_namespace" {
  type        = string
  description = "Namespace for Argo CD in quickhaul-aks"
  default     = "argocd"
}

variable "monitoring_namespace" {
  type        = string
  description = "Namespace for monitoring in quickhaul-aks"
  default     = "monitoring"
}

variable "workload_identity_name" {
  type        = string
  description = "Managed Identity name for ResolveOps pods"
  default     = "id-resolveops-workload-01"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name"
  default     = "resolveopssa01"
}

variable "workload_identity_service_account" {
  type        = string
  description = "Kubernetes service account federated to the Workload Identity"
  default     = "resolveops-workload-sa"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}

variable "authorized_ip_ranges" {
  type        = list(string)
  description = "Authorized IP ranges for AKS API server access"
  default     = []
}
