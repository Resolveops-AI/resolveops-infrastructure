data "azurerm_client_config" "current" {}

# --- Cluster ---
output "quickhaul_aks_name" {
  value       = module.aks.name
  description = "Name of the QuickHaul AKS cluster"
}

# --- Namespaces ---
output "quickhaul_dev_namespace" {
  value       = var.quickhaul_dev_namespace
  description = "Kubernetes namespace for QuickHaul dev workloads"
}

output "quickhaul_prod_namespace" {
  value       = var.quickhaul_prod_namespace
  description = "Kubernetes namespace for QuickHaul prod workloads"
}

output "argocd_namespace" {
  value       = var.argocd_namespace
  description = "Kubernetes namespace where Argo CD is installed"
}

# --- ACR (shared, read from resolveops environment) ---
output "acr_name" {
  value       = data.azurerm_container_registry.shared_acr.name
  description = "ACR Name (shared registry)"
}

output "acr_login_server" {
  value       = data.azurerm_container_registry.shared_acr.login_server
  description = "ACR Login Server (shared registry)"
}

# --- Resource Groups ---
output "resource_group_name" {
  value       = module.resource_group.name
  description = "QuickHaul Resource Group Name"
}

# --- Key Vault ---
output "key_vault_name" {
  value       = module.key_vault.name
  description = "Key Vault Name for QuickHaul"
}

output "key_vault_uri" {
  value       = module.key_vault.uri
  description = "Key Vault URI"
}

# --- Storage ---
output "storage_account_name" {
  value       = module.storage_account.name
  description = "Storage Account Name"
}

# --- Workload Identity ---
output "workload_identity_client_id" {
  value       = module.workload_identity.client_id
  description = "Workload Identity Client ID for QuickHaul services"
}

output "workload_identity_principal_id" {
  value       = module.workload_identity.principal_id
  description = "Workload Identity Principal ID"
}

# --- Identity ---
output "tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Azure Tenant ID"
}
