output "id" {
  value       = azurerm_user_assigned_identity.this.id
  description = "The ID of the User Assigned Identity"
}

output "client_id" {
  value       = azurerm_user_assigned_identity.this.client_id
  description = "The Client ID of the User Assigned Identity"
}

output "principal_id" {
  value       = azurerm_user_assigned_identity.this.principal_id
  description = "The Principal ID of the User Assigned Identity"
}
