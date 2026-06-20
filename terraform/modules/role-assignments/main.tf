# AKS AcrPull
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = var.aks_kubelet_identity_object_id
}

# Workload Identity Storage Blob Data Contributor
resource "azurerm_role_assignment" "workload_identity_storage" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.workload_identity_principal_id
}

# Workload Identity Key Vault Secrets User
resource "azurerm_role_assignment" "workload_identity_kv" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.workload_identity_principal_id
}
