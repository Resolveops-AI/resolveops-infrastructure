locals {
  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
  })
}

module "resource_group" {
  source   = "../../modules/resource-group"
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

module "networking" {
  source              = "../../modules/networking"
  vnet_name           = var.vnet_name
  location            = var.location
  resource_group_name = module.resource_group.name
  vnet_address_space  = var.vnet_address_space
  subnets             = var.subnets
  tags                = local.tags
}

module "acr" {
  source              = "../../modules/acr"
  name                = var.acr_name
  resource_group_name = module.resource_group.name
  location            = var.location
  sku                 = "Basic" # Keep simple for demo/resolveops platform
  tags                = local.tags
}

module "log_analytics" {
  source              = "../../modules/log-analytics"
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

# AKS cluster — hosts ResolveOps + QuickHaul workloads
module "aks" {
  source                     = "../../modules/aks"
  cluster_name               = var.resolveops_aks_name
  location                   = var.location
  resource_group_name        = module.resource_group.name
  vnet_subnet_id             = module.networking.subnet_ids["aks"]
  private_cluster_enabled    = var.enable_private_aks
  log_analytics_workspace_id = module.log_analytics.id
  node_vm_size               = "Standard_B2ps_v2"
  node_count                 = 2
  tags                       = local.tags

  depends_on = [
    module.networking
  ]
}

module "key_vault" {
  source                     = "../../modules/key-vault"
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = module.resource_group.name
  soft_delete_retention_days = 7
  tags                       = local.tags
}

module "storage_account" {
  source              = "../../modules/storage-account"
  name                = var.storage_account_name
  location            = var.location
  resource_group_name = module.resource_group.name
  replication_type    = "LRS"
  tags                = local.tags
}

# Workload Identity for ResolveOps platform services (e.g., auth-service, ai-rca-service)
module "workload_identity" {
  source                    = "../../modules/workload-identity"
  name                      = var.workload_identity_name
  location                  = var.location
  resource_group_name       = module.resource_group.name
  oidc_issuer_url           = module.aks.oidc_issuer_url
  service_account_namespace = var.resolveops_namespace
  service_account_name      = var.workload_identity_service_account
  tags                      = local.tags

  depends_on = [
    module.aks
  ]
}

# RBAC: allow resolveops-aks kubelet to pull from ACR, and workload identity to access KV/storage
module "role_assignments" {
  source                         = "../../modules/role-assignments"
  acr_id                         = module.acr.id
  aks_kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  storage_account_id             = module.storage_account.id
  key_vault_id                   = module.key_vault.id
  workload_identity_principal_id = module.workload_identity.principal_id

  depends_on = [
    module.aks,
    module.acr,
    module.storage_account,
    module.key_vault,
    module.workload_identity
  ]
}

module "service_bus" {
  source              = "../../modules/service-bus"
  name                = "${var.project_name}-sb-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

# Terraform-managed Kubernetes namespaces in resolveops-aks.
# Application workloads are deployed by Helm/Argo CD — Terraform only bootstraps the namespace objects.
module "resolveops_namespaces" {
  source = "../../modules/kubernetes-namespaces"

  namespaces = [
    var.resolveops_namespace,
    "quickhaul-dev",
    "quickhaul-prod",
  ]

  labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "cluster"                      = var.resolveops_aks_name
  }

  depends_on = [
    module.aks
  ]
}
