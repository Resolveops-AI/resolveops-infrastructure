resource "azurerm_servicebus_namespace" "this" {
  # checkov:skip=CKV_AZURE_201: Customer Managed Keys (CMK) are only available in the Premium tier. Standard tier is required for cost control.
  # checkov:skip=CKV_AZURE_204: Public network access is required because Standard tier does not support Private Endpoints.
  # checkov:skip=CKV_AZURE_199: Double encryption is only available in the Premium tier. Standard tier is required for cost control.

  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.sku
  public_network_access_enabled = true # Standard tier requires public network access
  minimum_tls_version           = "1.2"
  local_auth_enabled            = false

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

locals {
  all_queues = merge(
    { for q in var.queue_names : q => {} },
    var.queues_config
  )
}

resource "azurerm_servicebus_queue" "queues" {
  for_each                             = local.all_queues
  name                                 = each.key
  namespace_id                         = azurerm_servicebus_namespace.this.id
  dead_lettering_on_message_expiration = try(each.value.dead_lettering_on_message_expiration, false)
  default_message_ttl                  = try(each.value.default_message_ttl, null)
  max_delivery_count                   = try(each.value.max_delivery_count, 10)
}
