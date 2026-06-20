output "id" {
  value       = var.enabled ? azurerm_servicebus_namespace.this[0].id : null
  description = "The ID of the Service Bus namespace"
}

output "name" {
  value       = var.enabled ? azurerm_servicebus_namespace.this[0].name : null
  description = "The name of the Service Bus namespace"
}
