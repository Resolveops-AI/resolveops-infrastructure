output "aks_cluster_name" {
  value       = module.resolveops_aks.name
  description = "Shared AKS cluster name"
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
  description = "Argo CD namespace"
}

output "monitoring_namespace" {
  value       = var.monitoring_namespace
  description = "Monitoring namespace"
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

output "ai_service_name" {
  value       = module.ai.name
  description = "The name of the Azure AI Service"
}

output "ai_endpoint" {
  value       = module.ai.endpoint
  description = "The endpoint of the Azure AI Service"
}

output "service_bus_namespace_name" {
  value       = module.service_bus.namespace_name
  description = "The name of the Service Bus namespace."
}

output "service_bus_namespace_id" {
  value       = module.service_bus.namespace_id
  description = "The ID of the Service Bus namespace."
}

output "service_bus_queue_names" {
  value       = var.service_bus_queue_names
  description = "List of created Service Bus queues."
}
