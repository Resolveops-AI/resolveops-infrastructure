locals {
  tags = merge(var.tags, {
    Project   = var.project_name
    ManagedBy = "terraform"
  })
}

data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Shared Resource Group
# All platform resources (ACR, Key Vault, Log Analytics, both AKS clusters)
# live in one resource group for simplicity at demo scale.
# ---------------------------------------------------------------------------
module "resource_group" {
  source   = "../modules/resource-group"
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# Networking
# ---------------------------------------------------------------------------
module "networking" {
  source              = "../modules/networking"
  vnet_name           = var.vnet_name
  location            = var.location
  resource_group_name = module.resource_group.name
  vnet_address_space  = var.vnet_address_space
  subnets             = var.subnets
  tags                = local.tags
}

# ---------------------------------------------------------------------------
# Shared Azure Container Registry
# Both AKS clusters pull images from this single ACR.
# ---------------------------------------------------------------------------
module "acr" {
  source              = "../modules/acr"
  name                = var.acr_name
  resource_group_name = module.resource_group.name
  location            = var.location
  sku                 = "Basic"
  tags                = local.tags
}

# ---------------------------------------------------------------------------
# Shared Log Analytics Workspace
# Both AKS clusters ship Container Insights metrics here.
# ---------------------------------------------------------------------------
module "log_analytics" {
  source              = "../modules/log-analytics"
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

# ---------------------------------------------------------------------------
# Key Vault — ResolveOps platform secrets (API keys, operator tokens)
# RBAC-enabled; no access policies. Workload Identity is used by pods.
# ---------------------------------------------------------------------------
module "key_vault" {
  source                     = "../modules/key-vault"
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = module.resource_group.name
  soft_delete_retention_days = 7
  tags                       = local.tags
}

# ---------------------------------------------------------------------------
# Cluster 1 — resolveops-aks
# Runs all ResolveOps AI platform microservices.
# Single cluster, single namespace (resolveops). No dev/prod split.
# ---------------------------------------------------------------------------
module "resolveops_aks" {
  source                     = "../modules/aks"
  cluster_name               = var.resolveops_aks_name
  location                   = var.location
  resource_group_name        = module.resource_group.name
  dns_prefix                 = "${var.resolveops_aks_name}-dns"
  vnet_subnet_id             = module.networking.subnet_ids["resolveops-aks"]
  log_analytics_workspace_id = module.log_analytics.id
  system_node_vm_size        = "Standard_B2s"
  system_node_auto_scaling   = true
  system_node_min_count      = 1
  system_node_max_count      = 3
  tags                       = local.tags

  depends_on = [module.networking]
}

# ---------------------------------------------------------------------------
# Cluster 2 — quickhaul-aks
# Runs the QuickHaul Transits workload application.
# Two namespaces (quickhaul-dev, quickhaul-prod) managed by Argo CD.
# ---------------------------------------------------------------------------
module "quickhaul_aks" {
  source                     = "../modules/aks"
  cluster_name               = var.quickhaul_aks_name
  location                   = var.location
  resource_group_name        = module.resource_group.name
  dns_prefix                 = "${var.quickhaul_aks_name}-dns"
  vnet_subnet_id             = module.networking.subnet_ids["quickhaul-aks"]
  log_analytics_workspace_id = module.log_analytics.id
  system_node_vm_size        = "Standard_B2s"
  system_node_auto_scaling   = true
  system_node_min_count      = 1
  system_node_max_count      = 3
  tags                       = local.tags

  depends_on = [module.networking]
}

# ---------------------------------------------------------------------------
# Workload Identity — ResolveOps platform pods (auth-service, ai-rca-service, etc.)
# Federated to the resolveops namespace in resolveops-aks.
# ---------------------------------------------------------------------------
module "workload_identity" {
  source                    = "../modules/workload-identity"
  name                      = var.workload_identity_name
  location                  = var.location
  resource_group_name       = module.resource_group.name
  oidc_issuer_url           = module.resolveops_aks.oidc_issuer_url
  service_account_namespace = var.resolveops_namespace
  service_account_name      = var.workload_identity_service_account
  tags                      = local.tags

  depends_on = [module.resolveops_aks]
}

# ---------------------------------------------------------------------------
# RBAC — AcrPull for resolveops-aks kubelet identity
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "resolveops_aks_acr_pull" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.resolveops_aks.kubelet_identity_object_id

  depends_on = [module.resolveops_aks, module.acr]
}

# ---------------------------------------------------------------------------
# RBAC — AcrPull for quickhaul-aks kubelet identity
# Both clusters pull from the same shared ACR.
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "quickhaul_aks_acr_pull" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.quickhaul_aks.kubelet_identity_object_id

  depends_on = [module.quickhaul_aks, module.acr]
}

# ---------------------------------------------------------------------------
# RBAC — Workload Identity access to Key Vault (platform secrets)
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "workload_identity_kv" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.workload_identity.principal_id

  depends_on = [module.key_vault, module.workload_identity]
}

# ---------------------------------------------------------------------------
# Kubernetes Namespace — resolveops in resolveops-aks
# Platform pods land here. Terraform creates the namespace; Helm deploys apps.
# ---------------------------------------------------------------------------
module "resolveops_namespaces" {
  source = "../modules/kubernetes-namespaces"

  providers = {
    kubernetes = kubernetes.resolveops
  }

  namespaces = [var.resolveops_namespace]

  labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "cluster"                      = var.resolveops_aks_name
  }

  depends_on = [module.resolveops_aks]
}

# ---------------------------------------------------------------------------
# Kubernetes Namespaces — quickhaul-dev, quickhaul-prod, argocd in quickhaul-aks
# QuickHaul needs dev/prod separation for Argo CD GitOps env promotion.
# argocd namespace is bootstrapped here; Argo CD itself is installed by Helm.
# ---------------------------------------------------------------------------
module "quickhaul_namespaces" {
  source = "../modules/kubernetes-namespaces"

  providers = {
    kubernetes = kubernetes.quickhaul
  }

  namespaces = [
    var.quickhaul_dev_namespace,
    var.quickhaul_prod_namespace,
    var.argocd_namespace,
  ]

  labels = {
    "app.kubernetes.io/managed-by" = "terraform"
    "cluster"                      = var.quickhaul_aks_name
  }

  depends_on = [module.quickhaul_aks]
}
