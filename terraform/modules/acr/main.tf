resource "azurerm_container_registry" "this" {
  # checkov:skip=CKV_AZURE_139: Skipped for low-cost demo deployment - public network access is needed for demo developers
  # checkov:skip=CKV_AZURE_237: Skipped for low-cost demo deployment - dedicated data endpoints are not needed for basic registry
  # checkov:skip=CKV_AZURE_166: Skipped for low-cost demo deployment - image quarantine/scan policy is not needed for demo
  # checkov:skip=CKV_AZURE_233: Skipped for low-cost demo deployment - zone redundancy is too expensive for basic tier
  # checkov:skip=CKV_AZURE_164: Skipped for low-cost demo deployment - content trust/signed images not needed for demo
  # checkov:skip=CKV_AZURE_167: Skipped for low-cost demo deployment - manifest retention policy is not needed for demo
  # checkov:skip=CKV_AZURE_163: Skipped for low-cost demo deployment - vulnerability scanning is not needed for demo
  # checkov:skip=CKV_AZURE_165: Skipped for low-cost demo deployment - geo-replication is too expensive for basic tier

  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  tags                = var.tags
}
