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
  vnet_subnet_id             = module.networking.subnet_ids["resolveops-aks"]
  private_cluster_enabled    = true
  log_analytics_workspace_id = module.log_analytics.id
  
  system_node_vm_size        = var.system_node_vm_size
  system_node_min_count      = var.system_node_min_count
  system_node_max_count      = var.system_node_max_count
  user_node_vm_size          = var.user_node_vm_size
  user_node_min_count        = var.user_node_min_count
  user_node_max_count        = var.user_node_max_count
  enable_system_pool_taint   = var.enable_system_pool_taint

  tags                       = var.tags

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
  vm_size              = "Standard_B2s_v2"
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

# Kubernetes namespaces (resolveops, quickhaul-dev, quickhaul-prod, argocd, monitoring)
# are NOT created here. The private AKS API server is unreachable from the GitHub Actions
# runner. Namespaces are created post-provisioning via ArgoCD or from the jumpbox.
# See docs/post-provisioning.md for the setup runbook.

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

# Private Endpoint for Key Vault
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

# Role Assignment so Terraform can read/write secrets inside the Key Vault
resource "azurerm_role_assignment" "tf_kv_secrets_officer" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Azure RBAC is eventually consistent — wait for the role assignment to propagate
resource "time_sleep" "wait_for_kv_rbac" {
  depends_on      = [azurerm_role_assignment.tf_kv_secrets_officer]
  create_duration = "4m"
}

# Azure AI Service (OpenAI)
module "ai" {
  source              = "../modules/cognitive-services"
  name                = var.ai_service_name
  location            = var.ai_location
  resource_group_name = module.resource_group.name
  sku_name            = var.ai_sku_name
  tags                = var.tags
}

# Cannot create secrets via Terraform GitHub Actions runner when Key Vault public network access is disabled.
# Store AI Service Endpoint in Key Vault
resource "azurerm_key_vault_secret" "ai_endpoint" {
  name            = "resolveops-ai-endpoint"
  value           = module.ai.endpoint
  key_vault_id    = module.key_vault.id
  content_type    = "text/plain"
  expiration_date = "2030-12-31T23:59:59Z"

  depends_on = [time_sleep.wait_for_kv_rbac]
}

# Store AI Service Key securely in Key Vault (never outputted in plain text)
resource "azurerm_key_vault_secret" "ai_key" {
  name            = "resolveops-ai-key"
  value           = module.ai.primary_access_key
  key_vault_id    = module.key_vault.id
  content_type    = "text/plain"
  expiration_date = "2030-12-31T23:59:59Z"

  depends_on = [time_sleep.wait_for_kv_rbac]
}

# Private Endpoint for Azure AI Service
module "pe_ai" {
  source                         = "../modules/private-endpoint"
  name                           = "pe-${var.ai_service_name}"
  location                       = var.location
  resource_group_name            = module.resource_group.name
  subnet_id                      = module.networking.subnet_ids["snet-private-endpoints"]
  private_connection_resource_id = module.ai.id
  subresource_names              = ["account"]
  private_dns_zone_ids           = [azurerm_private_dns_zone.ai_dns.id]
  tags                           = var.tags
}

# Azure Service Bus for ResolveOps AI async workflows
module "service_bus" {
  source              = "../modules/service-bus"
  name                = var.service_bus_namespace_name
  location            = var.location
  resource_group_name = module.resource_group.name
  sku                 = var.service_bus_sku
  queue_names         = var.service_bus_queue_names
  tags                = var.tags
}

# Generate random password for PostgreSQL
resource "random_password" "postgres" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Azure PostgreSQL Flexible Server
module "postgres" {
  source              = "../modules/postgresql"
  name                = "psql-resolveops-dev-03"
  resource_group_name = module.resource_group.name
  location            = var.location
  admin_username      = var.postgres_admin_username
  admin_password      = random_password.postgres.result
  sku_name            = var.postgres_sku_name
  storage_mb          = var.postgres_storage_mb
  version_pg          = var.postgres_version
  delegated_subnet_id = null
  private_dns_zone_id = null
  tags                = var.tags

  databases = ["resolveopsdb"]
}

# Private Endpoint for PostgreSQL
module "pe_postgres" {
  source                         = "../modules/private-endpoint"
  name                           = "pe-resolveops-pg"
  location                       = var.location
  resource_group_name            = module.resource_group.name
  subnet_id                      = module.networking.subnet_ids["snet-private-endpoints"]
  private_connection_resource_id = module.postgres.id
  subresource_names              = ["postgresqlServer"]
  private_dns_zone_ids           = [azurerm_private_dns_zone.postgres_dns.id]
  tags                           = var.tags
}

# Store database-url in Key Vault
resource "azurerm_key_vault_secret" "database_url" {
  name            = "database-url"
  value           = "postgresql://${var.postgres_admin_username}:${random_password.postgres.result}@${module.postgres.fqdn}:5432/resolveopsdb?sslmode=require"
  key_vault_id    = module.key_vault.id
  content_type    = "text/plain"
  expiration_date = "2027-12-31T23:59:59Z"

  depends_on = [time_sleep.wait_for_kv_rbac]
}

# Storage Account
module "storage_account" {
  source              = "../modules/storage-account"
  name                = var.storage_account_name
  resource_group_name = module.resource_group.name
  location            = var.location
  replication_type    = "GRS"
  tags                = var.tags
}

# Blob Containers
resource "azurerm_storage_container" "reports" {
  name                  = "reports"
  storage_account_id    = module.storage_account.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "diagrams" {
  name                  = "diagrams"
  storage_account_id    = module.storage_account.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_id    = module.storage_account.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "solutions" {
  name                  = "solutions"
  storage_account_id    = module.storage_account.id
  container_access_type = "private"
}

# Private Endpoint for Blob Storage
module "pe_blob" {
  source                         = "../modules/private-endpoint"
  name                           = "pe-${var.storage_account_name}-blob"
  location                       = var.location
  resource_group_name            = module.resource_group.name
  subnet_id                      = module.networking.subnet_ids["snet-private-endpoints"]
  private_connection_resource_id = module.storage_account.id
  subresource_names              = ["blob"]
  private_dns_zone_ids           = [azurerm_private_dns_zone.blob_dns.id]
  tags                           = var.tags
}
