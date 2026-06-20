data "azurerm_client_config" "current" {}

# --- Cluster ---
output "resolveops_aks_name" {
  value       = module.aks.name
  description = "Name of the ResolveOps AKS cluster"
}

# --- Namespaces ---
output "resolveops_namespace" {
  value       = var.resolveops_namespace
  description = "Kubernetes namespace where ResolveOps platform microservices are deployed"
}

# --- ACR ---
output "acr_name" {
  value       = module.acr.name
  description = "ACR Name"
}

output "acr_login_server" {
  value       = module.acr.login_server
  description = "ACR Login Server"
}

# --- Resource Group ---
output "resource_group_name" {
  value       = module.resource_group.name
  description = "ResolveOps Resource Group Name"
}

# --- Key Vault ---
output "key_vault_name" {
  value       = module.key_vault.name
  description = "Key Vault Name"
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
  description = "Workload Identity Client ID for ResolveOps services"
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

output "oidc_issuer_url" {
  value       = module.aks.oidc_issuer_url
  description = "AKS OIDC Issuer URL for Workload Identity federation"
}
