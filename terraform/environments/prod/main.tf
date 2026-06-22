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

# ACR is referenced here so the QuickHaul cluster can be granted AcrPull.
# The ACR itself is owned by the resolveops (dev) environment; we use a data
# source to fetch its ID without managing it from this root.
data "azurerm_container_registry" "shared_acr" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

module "log_analytics" {
  source              = "../../modules/log-analytics"
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

# Cluster 2: quickhaul-aks — hosts the QuickHaul Transits workload application.
module "aks" {
  source                  = "../../modules/aks"
  cluster_name            = var.quickhaul_aks_name
  location                = var.location
  resource_group_name     = module.resource_group.name
  vnet_subnet_id          = module.networking.subnet_ids["aks"]
  private_cluster_enabled = true
  node_vm_size            = "Standard_B2ps_v2"
  node_count              = 2
  tags                    = local.tags

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

# Workload Identity for QuickHaul services that need Azure resource access.
module "workload_identity" {
  source                    = "../../modules/workload-identity"
  name                      = var.workload_identity_name
  location                  = var.location
  resource_group_name       = module.resource_group.name
  oidc_issuer_url           = module.aks.oidc_issuer_url
  service_account_namespace = var.quickhaul_dev_namespace
  service_account_name      = var.workload_identity_service_account
  tags                      = local.tags

  depends_on = [
    module.aks
  ]
}

# RBAC: allow quickhaul-aks kubelet to pull from the shared ACR.
# This is a separate resource (not via the role-assignments module) because the
# ACR is in a different resource group managed by the resolveops environment.
resource "azurerm_role_assignment" "quickhaul_aks_acr_pull" {
  scope                = data.azurerm_container_registry.shared_acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id

  depends_on = [module.aks]
}

# Additional RBAC for Key Vault and Storage via the shared module.
module "role_assignments" {
  source                         = "../../modules/role-assignments"
  acr_id                         = data.azurerm_container_registry.shared_acr.id
  aks_kubelet_identity_object_id = module.aks.kubelet_identity_object_id
  storage_account_id             = module.storage_account.id
  key_vault_id                   = module.key_vault.id
  workload_identity_principal_id = module.workload_identity.principal_id

  depends_on = [
    module.aks,
    module.storage_account,
    module.key_vault,
    module.workload_identity
  ]
}

module "service_bus" {
  source = "../../modules/service-bus"
  # enabled             = var.enable_service_bus
  name                = "${var.project_name}-sb-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

# Terraform-managed Kubernetes namespaces in quickhaul-aks.
# QuickHaul needs dev/prod namespace separation because Argo CD manages two
# separate GitOps environments (one per application environment).
# The argocd namespace is bootstrapped here so Argo CD can be installed by Helm.
# Application workloads are deployed by Helm/Argo CD — not by Terraform.
module "quickhaul_namespaces" {
  source = "../../modules/kubernetes-namespaces"

  namespaces = [
    var.quickhaul_dev_namespace,
    var.quickhaul_prod_namespace,
    var.argocd_namespace,
  ]

  labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "cluster"                      = var.quickhaul_aks_name
  }

  depends_on = [
    module.aks
  ]
}
