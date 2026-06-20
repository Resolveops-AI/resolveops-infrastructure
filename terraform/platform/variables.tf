variable "project_name" {
  type        = string
  description = "Project name used for tagging"
  default     = "resolveops"
}

variable "location" {
  type        = string
  description = "Azure region for all platform resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the shared platform resource group"
}

variable "vnet_name" {
  type        = string
  description = "Virtual network name"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the platform VNet"
}

# The platform VNet needs two subnets: one per AKS cluster.
# Example:
#   subnets = {
#     "resolveops-aks" = { address_prefixes = ["10.0.1.0/24"] }
#     "quickhaul-aks"  = { address_prefixes = ["10.0.2.0/24"] }
#   }
variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  description = "Subnet map — must include 'resolveops-aks' and 'quickhaul-aks' keys"
}

variable "acr_name" {
  type        = string
  description = "Name of the shared Azure Container Registry (must be globally unique)"
}

variable "log_analytics_workspace_name" {
  type        = string
  description = "Name of the shared Log Analytics Workspace"
}

variable "key_vault_name" {
  type        = string
  description = "Name of the ResolveOps platform Key Vault"
}

# ---------------------------------------------------------------------------
# Cluster 1: ResolveOps platform cluster
# ResolveOps AI has ONE cluster and ONE namespace — no environment split.
# ---------------------------------------------------------------------------
variable "resolveops_aks_name" {
  type        = string
  description = "Name of the ResolveOps AKS cluster"
  default     = "resolveops-aks"
}

# The single namespace where all ResolveOps microservices run.
variable "resolveops_namespace" {
  type        = string
  description = "Kubernetes namespace for ResolveOps platform microservices"
  default     = "resolveops"
}

# ---------------------------------------------------------------------------
# Cluster 2: QuickHaul workload cluster
# QuickHaul needs dev/prod namespaces for Argo CD GitOps env separation.
# ---------------------------------------------------------------------------
variable "quickhaul_aks_name" {
  type        = string
  description = "Name of the QuickHaul AKS cluster"
  default     = "quickhaul-aks"
}

variable "quickhaul_dev_namespace" {
  type        = string
  description = "QuickHaul development namespace"
  default     = "quickhaul-dev"
}

variable "quickhaul_prod_namespace" {
  type        = string
  description = "QuickHaul production namespace"
  default     = "quickhaul-prod"
}

variable "argocd_namespace" {
  type        = string
  description = "Argo CD namespace in the QuickHaul cluster"
  default     = "argocd"
}

# ---------------------------------------------------------------------------
# Workload Identity (ResolveOps platform pods)
# ---------------------------------------------------------------------------
variable "workload_identity_name" {
  type        = string
  description = "Name of the User Assigned Managed Identity for ResolveOps pods"
}

variable "workload_identity_service_account" {
  type        = string
  description = "Kubernetes service account name to federate with the Workload Identity"
  default     = "resolveops-workload-sa"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags applied to all resources"
  default     = {}
}
