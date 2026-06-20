variable "acr_id" {
  type        = string
  description = "ID of the Container Registry"
}

variable "aks_kubelet_identity_object_id" {
  type        = string
  description = "Object ID of the AKS kubelet identity"
}

variable "storage_account_id" {
  type        = string
  description = "ID of the Storage Account"
}

variable "key_vault_id" {
  type        = string
  description = "ID of the Key Vault"
}

variable "workload_identity_principal_id" {
  type        = string
  description = "Principal ID of the Workload Identity"
}
