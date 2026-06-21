output "name" {
  value       = data.azurerm_resource_group.this.name
  description = "The name of the resource group"
}

output "id" {
  value       = data.azurerm_resource_group.this.id
  description = "The ID of the resource group"
}

output "location" {
  value       = data.azurerm_resource_group.this.location
  description = "The location of the resource group"
}
