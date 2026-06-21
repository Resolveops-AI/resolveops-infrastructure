resource "azurerm_cognitive_account" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "OpenAI"
  sku_name                      = var.sku_name
  custom_subdomain_name         = var.name
  public_network_access_enabled = false

  identity {
    type = "SystemAssigned"
  }

  # checkov:skip=CKV_AZURE_247: "Data loss prevention not required"
  # checkov:skip=CKV_AZURE_236: "Local authentication is required for API keys"
  # checkov:skip=CKV2_AZURE_22: "Customer-managed key encryption not required for this demo"

  tags = var.tags
}
