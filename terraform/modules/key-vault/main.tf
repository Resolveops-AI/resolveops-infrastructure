data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  # checkov:skip=CKV2_AZURE_32: Private endpoint is created in platform main.tf using private-endpoint module
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = true

  sku_name = "standard"

  rbac_authorization_enabled    = true
  public_network_access_enabled = false

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = var.tags
}
