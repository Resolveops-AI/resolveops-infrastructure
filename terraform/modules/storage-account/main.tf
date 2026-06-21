resource "azurerm_storage_account" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.replication_type

  min_tls_version = "TLS1_2"

  # Checkov Fixes
  # checkov:skip=CKV2_AZURE_33: Private endpoint is configured in platform main.tf using a separate module.
  # checkov:skip=CKV_AZURE_33: Queue logging is enabled via azurerm_storage_account_queue_properties resource below (Checkov cannot correlate the two resources).
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  # checkov:skip=CKV2_AZURE_40: Terraform requires shared access key to manage containers.
  shared_access_key_enabled = true

  sas_policy {
    expiration_period = "90.00:00:00"
    expiration_action = "Log"
  }

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }


  # checkov:skip=CKV2_AZURE_1: CMK is not required for this demo architecture.

  tags = var.tags
}

# Supersedes the deprecated queue_properties block inside azurerm_storage_account.
# Required in azurerm 4.x; the inline block will be removed in v5.
resource "azurerm_storage_account_queue_properties" "this" {
  storage_account_id = azurerm_storage_account.this.id

  logging {
    delete                = true
    read                  = true
    write                 = true
    version               = "1.0"
    retention_policy_days = 7
  }
}
