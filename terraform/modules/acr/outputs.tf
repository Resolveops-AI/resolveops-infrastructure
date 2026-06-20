output "id" {
  value       = azurerm_container_registry.this.id
  description = "The ID of the container registry"
}

output "name" {
  value       = azurerm_container_registry.this.name
  description = "The name of the container registry"
}

output "login_server" {
  value       = azurerm_container_registry.this.login_server
  description = "The login server URL for the container registry"
}
