data "azurerm_client_config" "current" {}

# Resource group for all platform resources
module "resource_group" {
  source   = "../modules/resource-group"
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual network and subnets for both AKS clusters
module "networking" {
  source              = "../modules/networking"
  vnet_name           = var.vnet_name
  location            = var.location
  resource_group_name = module.resource_group.name
  vnet_address_space  = var.vnet_address_space
  subnets             = var.subnets
  tags                = var.tags
}

# Shared container registry — both clusters pull images from here
module "acr" {
  source              = "../modules/acr"
  name                = var.acr_name
  resource_group_name = module.resource_group.name
  location            = var.location
  sku                 = "Basic"
  tags                = var.tags
}

# Log Analytics workspace for AKS monitoring
module "log_analytics" {
  source              = "../modules/log-analytics"
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = var.tags
}

# Key Vault for ResolveOps platform secrets
module "key_vault" {
  source                     = "../modules/key-vault"
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = module.resource_group.name
  soft_delete_retention_days = 7
  tags                       = var.tags
}

# AKS cluster where ResolveOps AI platform runs
module "resolveops_aks" {
  source                     = "../modules/aks"
  cluster_name               = var.resolveops_aks_name
  location                   = var.location
  resource_group_name        = module.resource_group.name
  dns_prefix                 = var.resolveops_aks_name
  vnet_subnet_id             = module.networking.subnet_ids["resolveops-aks"]
  log_analytics_workspace_id = module.log_analytics.id
  system_node_vm_size        = "Standard_B2s"
  system_node_auto_scaling   = true
  system_node_min_count      = 1
  system_node_max_count      = 3
  tags                       = var.tags

  depends_on = [module.networking]
}

# AKS cluster where QuickHaul dev and prod workloads run
module "quickhaul_aks" {
  source                     = "../modules/aks"
  cluster_name               = var.quickhaul_aks_name
  location                   = var.location
  resource_group_name        = module.resource_group.name
  dns_prefix                 = var.quickhaul_aks_name
  vnet_subnet_id             = module.networking.subnet_ids["quickhaul-aks"]
  log_analytics_workspace_id = module.log_analytics.id
  system_node_vm_size        = "Standard_B2s"
  system_node_auto_scaling   = true
  system_node_min_count      = 1
  system_node_max_count      = 3
  tags                       = var.tags

  depends_on = [module.networking]
}

# Workload Identity for ResolveOps pods to access Key Vault without secrets
module "workload_identity" {
  source                    = "../modules/workload-identity"
  name                      = var.workload_identity_name
  location                  = var.location
  resource_group_name       = module.resource_group.name
  oidc_issuer_url           = module.resolveops_aks.oidc_issuer_url
  service_account_namespace = var.resolveops_namespace
  service_account_name      = var.workload_identity_service_account
  tags                      = var.tags

  depends_on = [module.resolveops_aks]
}

# Allows resolveops-aks nodes to pull images from ACR
resource "azurerm_role_assignment" "resolveops_acr_pull" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.resolveops_aks.kubelet_identity_object_id
}

# Allows quickhaul-aks nodes to pull images from ACR
resource "azurerm_role_assignment" "quickhaul_acr_pull" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.quickhaul_aks.kubelet_identity_object_id
}

# Allows ResolveOps pods to read secrets from Key Vault via Workload Identity
resource "azurerm_role_assignment" "resolveops_kv_secrets" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.workload_identity.principal_id
}

# Namespace in resolveops-aks where all ResolveOps services run
resource "kubernetes_namespace_v1" "resolveops" {
  provider = kubernetes.resolveops

  metadata {
    name = var.resolveops_namespace
  }

  depends_on = [module.resolveops_aks]
}

# Dev namespace in quickhaul-aks for QuickHaul development workloads
resource "kubernetes_namespace_v1" "quickhaul_dev" {
  provider = kubernetes.quickhaul

  metadata {
    name = var.quickhaul_dev_namespace
  }

  depends_on = [module.quickhaul_aks]
}

# Prod namespace in quickhaul-aks for QuickHaul production workloads
resource "kubernetes_namespace_v1" "quickhaul_prod" {
  provider = kubernetes.quickhaul

  metadata {
    name = var.quickhaul_prod_namespace
  }

  depends_on = [module.quickhaul_aks]
}

# Argo CD namespace in quickhaul-aks — Argo CD is installed here by Helm
resource "kubernetes_namespace_v1" "argocd" {
  provider = kubernetes.quickhaul

  metadata {
    name = var.argocd_namespace
  }

  depends_on = [module.quickhaul_aks]
}
