output "vnet_id" {
  value       = azurerm_virtual_network.this.id
  description = "The ID of the virtual network"
}

output "vnet_name" {
  value       = azurerm_virtual_network.this.name
  description = "The name of the virtual network"
}

output "subnet_ids" {
  value = merge(
    { for k, v in azurerm_subnet.subnets : k => v.id },
    contains(keys(var.subnets), "AzureBastionSubnet") ? { "AzureBastionSubnet" = azurerm_subnet.bastion[0].id } : {}
  )
  description = "Map of subnet names to their IDs"
}
