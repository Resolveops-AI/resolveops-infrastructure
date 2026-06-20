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
  sku                 = "Premium" # Use Premium for Prod
  tags                = local.tags
}

module "log_analytics" {
  source              = "../../modules/log-analytics"
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

module "aks" {
  source                     = "../../modules/aks"
  cluster_name               = var.aks_cluster_name
  location                   = var.location
  resource_group_name        = module.resource_group.name
  dns_prefix                 = "${var.aks_cluster_name}-dns"
  vnet_subnet_id             = module.networking.subnet_ids["aks"]
  log_analytics_workspace_id = module.log_analytics.id
  system_node_vm_size        = "Standard_D4s_v3" # Larger size for prod
  system_node_auto_scaling   = true
  system_node_min_count      = 2
  system_node_max_count      = 5
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
  soft_delete_retention_days = 90 # Production retention
  tags                       = local.tags
}

module "storage_account" {
  source              = "../../modules/storage-account"
  name                = var.storage_account_name
  location            = var.location
  resource_group_name = module.resource_group.name
  replication_type    = "GRS" # Geo-redundant for prod
  tags                = local.tags
}

module "workload_identity" {
  source                    = "../../modules/workload-identity"
  name                      = var.workload_identity_name
  location                  = var.location
  resource_group_name       = module.resource_group.name
  oidc_issuer_url           = module.aks.oidc_issuer_url
  service_account_namespace = var.aks_namespace
  service_account_name      = var.workload_identity_service_account
  tags                      = local.tags

  depends_on = [
    module.aks
  ]
}

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
  enabled             = var.enable_service_bus
  name                = "${var.project_name}-sb-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}
