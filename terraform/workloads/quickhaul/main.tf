data "azurerm_client_config" "current" {}

# Read the quickhaul-aks cluster created by terraform/platform
data "azurerm_kubernetes_cluster" "quickhaul_aks" {
  name                = var.quickhaul_aks_name
  resource_group_name = var.platform_resource_group_name
}

# Read the shared ACR created by terraform/platform
data "azurerm_container_registry" "shared_acr" {
  name                = var.acr_name
  resource_group_name = var.platform_resource_group_name
}

# Resource group for QuickHaul workload resources
module "resource_group" {
  source   = "../../modules/resource-group"
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Key Vault for QuickHaul application secrets
module "key_vault" {
  source                     = "../../modules/key-vault"
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = module.resource_group.name
  soft_delete_retention_days = 7
  tags                       = var.tags
}

# Workload Identity for QuickHaul pods to access Key Vault
module "workload_identity" {
  source                    = "../../modules/workload-identity"
  name                      = var.workload_identity_name
  location                  = var.location
  resource_group_name       = module.resource_group.name
  oidc_issuer_url           = data.azurerm_kubernetes_cluster.quickhaul_aks.oidc_issuer_url
  service_account_namespace = var.quickhaul_dev_namespace
  service_account_name      = var.workload_identity_service_account
  tags                      = var.tags
}

# Allows QuickHaul pods to read secrets from Key Vault
resource "azurerm_role_assignment" "quickhaul_kv_secrets" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.workload_identity.principal_id
}
