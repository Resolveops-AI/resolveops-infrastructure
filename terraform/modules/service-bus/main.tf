resource "azurerm_servicebus_namespace" "this" {
  count               = var.enabled ? 1 : 0
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  tags                = var.tags
}
