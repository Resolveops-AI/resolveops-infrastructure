# Note: data.azurerm_client_config.current is declared in main.tf

output "quickhaul_aks_name" {
  value       = data.azurerm_kubernetes_cluster.quickhaul_aks.name
  description = "QuickHaul AKS cluster name"
}

output "quickhaul_dev_namespace" {
  value       = var.quickhaul_dev_namespace
  description = "QuickHaul dev namespace"
}

output "quickhaul_prod_namespace" {
  value       = var.quickhaul_prod_namespace
  description = "QuickHaul prod namespace"
}

output "resource_group_name" {
  value       = module.resource_group.name
  description = "QuickHaul resource group name"
}

output "key_vault_name" {
  value       = module.key_vault.name
  description = "QuickHaul Key Vault name"
}

output "acr_name" {
  value       = data.azurerm_container_registry.shared_acr.name
  description = "Shared ACR name"
}

output "acr_login_server" {
  value       = data.azurerm_container_registry.shared_acr.login_server
  description = "Shared ACR login server"
}

output "workload_identity_client_id" {
  value       = module.workload_identity.client_id
  description = "QuickHaul Workload Identity Client ID"
}

output "azure_tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Azure Tenant ID"
}
