variable "location" {
  type        = string
  description = "Azure region"
}

# ---------------------------------------------------------------------------
# Platform references — read-only from terraform/platform/ state
# ---------------------------------------------------------------------------
variable "platform_resource_group_name" {
  type        = string
  description = "Resource group name of the shared platform (where quickhaul-aks lives)"
}

variable "quickhaul_aks_name" {
  type        = string
  description = "Name of the QuickHaul AKS cluster (must match platform output)"
  default     = "quickhaul-aks"
}

variable "acr_name" {
  type        = string
  description = "Name of the shared ACR (must match platform output)"
}

variable "quickhaul_dev_namespace" {
  type        = string
  description = "QuickHaul development namespace (must match platform output)"
  default     = "quickhaul-dev"
}

variable "quickhaul_prod_namespace" {
  type        = string
  description = "QuickHaul production namespace (must match platform output)"
  default     = "quickhaul-prod"
}

# ---------------------------------------------------------------------------
# QuickHaul-specific resources
# ---------------------------------------------------------------------------
variable "resource_group_name" {
  type        = string
  description = "QuickHaul workload resource group name"
}

variable "key_vault_name" {
  type        = string
  description = "QuickHaul Key Vault name"
}

variable "workload_identity_name" {
  type        = string
  description = "QuickHaul Workload Identity name"
}

variable "workload_identity_service_account" {
  type        = string
  description = "Kubernetes service account name for QuickHaul Workload Identity federation"
  default     = "quickhaul-workload-sa"
}

variable "tags" {
  type        = map(string)
  description = "Additional tags"
  default     = {}
}
