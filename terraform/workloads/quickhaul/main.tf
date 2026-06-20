locals {
  tags = merge(var.tags, {
    Project   = "quickhaul"
    ManagedBy = "terraform"
  })
}

data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Read the QuickHaul AKS cluster created by terraform/platform/
# The cluster and its namespaces are owned by the platform root.
# This workload root only manages QuickHaul-specific Azure resources.
# ---------------------------------------------------------------------------
data "azurerm_kubernetes_cluster" "quickhaul_aks" {
  name                = var.quickhaul_aks_name
  resource_group_name = var.platform_resource_group_name
}

# ---------------------------------------------------------------------------
# Read the shared ACR created by terraform/platform/
# ---------------------------------------------------------------------------
data "azurerm_container_registry" "shared_acr" {
  name                = var.acr_name
  resource_group_name = var.platform_resource_group_name
}

# ---------------------------------------------------------------------------
# QuickHaul Resource Group
# Separate resource group so QuickHaul billing/RBAC is independently auditable.
# ---------------------------------------------------------------------------
module "resource_group" {
  source   = "../../modules/resource-group"
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# QuickHaul Key Vault — workload-specific secrets (DB passwords, API tokens)
# Separate from the ResolveOps platform Key Vault by design.
# ---------------------------------------------------------------------------
module "key_vault" {
  source                     = "../../modules/key-vault"
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = module.resource_group.name
  soft_delete_retention_days = 7
  tags                       = local.tags
}

# ---------------------------------------------------------------------------
# QuickHaul Workload Identity
# Federated to the quickhaul-dev namespace in quickhaul-aks.
# Used by QuickHaul pods to access Key Vault and other Azure resources.
# ---------------------------------------------------------------------------
module "workload_identity" {
  source                    = "../../modules/workload-identity"
  name                      = var.workload_identity_name
  location                  = var.location
  resource_group_name       = module.resource_group.name
  oidc_issuer_url           = data.azurerm_kubernetes_cluster.quickhaul_aks.oidc_issuer_url
  service_account_namespace = var.quickhaul_dev_namespace
  service_account_name      = var.workload_identity_service_account
  tags                      = local.tags
}

# ---------------------------------------------------------------------------
# RBAC — QuickHaul Workload Identity can read Key Vault secrets
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "quickhaul_workload_identity_kv" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.workload_identity.principal_id

  depends_on = [module.key_vault, module.workload_identity]
}
