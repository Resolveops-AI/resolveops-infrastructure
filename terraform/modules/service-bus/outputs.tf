output "namespace_name" {
  value       = azurerm_servicebus_namespace.this.name
  description = "The name of the Service Bus namespace."
}

output "namespace_id" {
  value       = azurerm_servicebus_namespace.this.id
  description = "The ID of the Service Bus namespace."
}
