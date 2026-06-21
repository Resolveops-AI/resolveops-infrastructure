output "resolveops_aks_name" {
  value       = module.resolveops_aks.name
  description = "ResolveOps AKS cluster name"
}

output "quickhaul_aks_name" {
  value       = module.quickhaul_aks.name
  description = "QuickHaul AKS cluster name"
}

output "resolveops_namespace" {
  value       = var.resolveops_namespace
  description = "Namespace where ResolveOps services run"
}

output "quickhaul_dev_namespace" {
  value       = var.quickhaul_dev_namespace
  description = "QuickHaul dev namespace"
}

output "quickhaul_prod_namespace" {
  value       = var.quickhaul_prod_namespace
  description = "QuickHaul prod namespace"
}

output "jumpbox_ssh_private_key" {
  value       = tls_private_key.jumpbox_ssh.private_key_pem
  description = "The SSH private key for the jumpbox VM"
  sensitive   = true
}

output "argocd_namespace" {
  value       = var.argocd_namespace
  description = "Argo CD namespace in quickhaul-aks"
}

output "monitoring_namespace" {
  value       = var.monitoring_namespace
  description = "Monitoring namespace in quickhaul-aks"
}

output "acr_name" {
  value       = module.acr.name
  description = "Container registry name"
}

output "acr_login_server" {
  value       = module.acr.login_server
  description = "Container registry login server"
}

output "resource_group_name" {
  value       = module.resource_group.name
  description = "Platform resource group name"
}

output "key_vault_name" {
  value       = module.key_vault.name
  description = "Key Vault name"
}

output "workload_identity_client_id" {
  value       = module.workload_identity.client_id
  description = "Workload Identity client ID for ResolveOps pods"
}

output "azure_tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Azure tenant ID"
}

output "resolveops_domain" {
  value       = "resolveops-ai.sathvikdevops.online"
  description = "ResolveOps application domain"
}

output "quickhaul_domain" {
  value       = "quickhaul.sathvikdevops.site"
  description = "QuickHaul application domain"
}

output "quickhaul_gateway_namespace" {
  value       = "gateway-system"
  description = "Namespace for Kong Gateway in QuickHaul AKS"
}
