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
  allowed_subnet_ids = [
    module.networking.subnet_ids["resolveops-aks"]
  ]
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
  system_node_vm_size        = "Standard_D2s_v7"
  system_node_auto_scaling   = true
  system_node_min_count      = 1
  system_node_max_count      = 2
  tags                       = var.tags
  private_cluster_enabled    = true

  enable_agic      = true
  appgw_gateway_id = module.appgw.id

  depends_on = [module.networking]
}

# Standalone Application Gateway for ResolveOps
module "appgw" {
  source              = "../modules/application-gateway"
  name                = "${var.resolveops_aks_name}-appgw"
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.networking.subnet_ids["appgw"]
  tags                = var.tags
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

# Generate SSH key for the jumpbox
resource "tls_private_key" "jumpbox_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Azure Bastion Host for secure access to the VNet
module "bastion" {
  source              = "../modules/bastion"
  name                = "resolveops-bastion"
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.networking.subnet_ids["AzureBastionSubnet"]
  tags                = var.tags
}

# Ubuntu Linux Jumpbox VM for managing private AKS clusters
module "jumpbox" {
  source               = "../modules/jumpbox"
  name                 = "resolveops-jumpbox"
  location             = var.location
  resource_group_name  = module.resource_group.name
  subnet_id            = module.networking.subnet_ids["jumpbox"]
  vm_size              = "Standard_B2s"
  admin_ssh_public_key = tls_private_key.jumpbox_ssh.public_key_openssh
  tags                 = var.tags

  depends_on = [module.resolveops_aks]
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

# Dev namespace in resolveops-aks for QuickHaul development workloads
resource "kubernetes_namespace_v1" "quickhaul_dev" {
  provider = kubernetes.resolveops

  metadata {
    name = var.quickhaul_dev_namespace
  }

  depends_on = [module.resolveops_aks]
}

# Prod namespace in resolveops-aks for QuickHaul production workloads
resource "kubernetes_namespace_v1" "quickhaul_prod" {
  provider = kubernetes.resolveops

  metadata {
    name = var.quickhaul_prod_namespace
  }

  depends_on = [module.resolveops_aks]
}

# Argo CD namespace in resolveops-aks — Argo CD is installed here by Helm
resource "kubernetes_namespace_v1" "argocd" {
  provider = kubernetes.resolveops

  metadata {
    name = var.argocd_namespace
  }

  depends_on = [module.resolveops_aks]
}

# Monitoring namespace in resolveops-aks — Prometheus and Grafana are installed here by Helm
resource "kubernetes_namespace_v1" "monitoring" {
  provider = kubernetes.resolveops

  metadata {
    name = var.monitoring_namespace
  }

  depends_on = [module.resolveops_aks]
}

# Private DNS Zones
resource "azurerm_private_dns_zone" "kv_dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = module.resource_group.name
}
resource "azurerm_private_dns_zone" "blob_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = module.resource_group.name
}
resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = module.resource_group.name
}
resource "azurerm_private_dns_zone" "sb_dns" {
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = module.resource_group.name
}
resource "azurerm_private_dns_zone" "acr_dns" {
  name                = "privatelink.azurecr.io"
  resource_group_name = module.resource_group.name
}
resource "azurerm_private_dns_zone" "ai_dns" {
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = module.resource_group.name
}

# VNet Links for DNS Zones
resource "azurerm_private_dns_zone_virtual_network_link" "kv_link" {
  name                  = "kv-link"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.kv_dns.name
  virtual_network_id    = module.networking.vnet_id
}
resource "azurerm_private_dns_zone_virtual_network_link" "blob_link" {
  name                  = "blob-link"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.blob_dns.name
  virtual_network_id    = module.networking.vnet_id
}
resource "azurerm_private_dns_zone_virtual_network_link" "postgres_link" {
  name                  = "postgres-link"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  virtual_network_id    = module.networking.vnet_id
}
resource "azurerm_private_dns_zone_virtual_network_link" "sb_link" {
  name                  = "sb-link"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.sb_dns.name
  virtual_network_id    = module.networking.vnet_id
}
resource "azurerm_private_dns_zone_virtual_network_link" "acr_link" {
  name                  = "acr-link"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.acr_dns.name
  virtual_network_id    = module.networking.vnet_id
}
resource "azurerm_private_dns_zone_virtual_network_link" "ai_link" {
  name                  = "ai-link"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.ai_dns.name
  virtual_network_id    = module.networking.vnet_id
}

# Private Endpoints for existing resources
module "pe_kv" {
  source                         = "../modules/private-endpoint"
  name                           = "pe-${var.key_vault_name}"
  location                       = var.location
  resource_group_name            = module.resource_group.name
  subnet_id                      = module.networking.subnet_ids["snet-private-endpoints"]
  private_connection_resource_id = module.key_vault.id
  subresource_names              = ["vault"]
  private_dns_zone_ids           = [azurerm_private_dns_zone.kv_dns.id]
  tags                           = var.tags
}
