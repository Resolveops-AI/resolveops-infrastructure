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
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the VNet"
}

variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  description = "Subnets map — must include 'resolveops-aks' and 'quickhaul-aks'"
}

variable "acr_name" {
  type        = string
  description = "Azure Container Registry name (must be globally unique)"
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Log Analytics workspace name"
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

variable "workload_identity_name" {
  type        = string
  description = "Managed Identity name for ResolveOps pods"
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
