# ---------------------------------------------------------------------------
# Cluster Identifiers
# ---------------------------------------------------------------------------
output "resolveops_aks_name" {
  value       = module.resolveops_aks.name
  description = "Name of the ResolveOps AKS cluster"
}

output "quickhaul_aks_name" {
  value       = module.quickhaul_aks.name
  description = "Name of the QuickHaul AKS cluster"
}

# ---------------------------------------------------------------------------
# Namespaces
# ---------------------------------------------------------------------------
output "resolveops_namespace" {
  value       = var.resolveops_namespace
  description = "Kubernetes namespace for ResolveOps platform microservices"
}

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
  description = "Kubernetes namespace where Argo CD is installed in quickhaul-aks"
}

# ---------------------------------------------------------------------------
# ACR
# ---------------------------------------------------------------------------
output "acr_name" {
  value       = module.acr.name
  description = "Name of the shared Azure Container Registry"
}

output "acr_login_server" {
  value       = module.acr.login_server
  description = "Login server URL for the shared ACR"
}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
output "resource_group_name" {
  value       = module.resource_group.name
  description = "Platform resource group name"
}

# ---------------------------------------------------------------------------
# Key Vault
# ---------------------------------------------------------------------------
output "key_vault_name" {
  value       = module.key_vault.name
  description = "Name of the ResolveOps platform Key Vault"
}

output "key_vault_uri" {
  value       = module.key_vault.uri
  description = "URI of the ResolveOps platform Key Vault"
}

# ---------------------------------------------------------------------------
# Workload Identity
# ---------------------------------------------------------------------------
output "workload_identity_client_id" {
  value       = module.workload_identity.client_id
  description = "Client ID of the ResolveOps Workload Identity"
}

output "workload_identity_principal_id" {
  value       = module.workload_identity.principal_id
  description = "Principal ID of the ResolveOps Workload Identity"
}

# ---------------------------------------------------------------------------
# Identity / Tenant
# ---------------------------------------------------------------------------
output "azure_tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Azure Active Directory Tenant ID"
}

output "resolveops_oidc_issuer_url" {
  value       = module.resolveops_aks.oidc_issuer_url
  description = "OIDC Issuer URL for resolveops-aks (for Workload Identity federation)"
}

output "quickhaul_oidc_issuer_url" {
  value       = module.quickhaul_aks.oidc_issuer_url
  description = "OIDC Issuer URL for quickhaul-aks"
}
