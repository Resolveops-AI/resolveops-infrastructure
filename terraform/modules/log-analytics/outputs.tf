output "id" {
  value       = azurerm_log_analytics_workspace.this.id
  description = "The ID of the Log Analytics Workspace"
}

output "name" {
  value       = azurerm_log_analytics_workspace.this.name
  description = "The name of the Log Analytics Workspace"
}
