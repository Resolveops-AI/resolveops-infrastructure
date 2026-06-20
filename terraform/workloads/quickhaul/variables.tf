variable "location" {
  type        = string
  description = "Azure region"
}

variable "platform_resource_group_name" {
  type        = string
  description = "Resource group where the platform resources (AKS, ACR) live"
}

variable "quickhaul_aks_name" {
  type        = string
  description = "QuickHaul AKS cluster name"
  default     = "quickhaul-aks"
}

variable "acr_name" {
  type        = string
  description = "Shared ACR name (created by terraform/platform)"
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

variable "resource_group_name" {
  type        = string
  description = "Resource group for QuickHaul workload resources"
}

variable "key_vault_name" {
  type        = string
  description = "Key Vault name for QuickHaul secrets"
}

variable "workload_identity_name" {
  type        = string
  description = "Managed Identity name for QuickHaul pods"
}

variable "workload_identity_service_account" {
  type        = string
  description = "Kubernetes service account federated to the Workload Identity"
  default     = "quickhaul-workload-sa"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
