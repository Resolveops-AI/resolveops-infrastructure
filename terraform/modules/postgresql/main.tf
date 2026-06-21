variable "name" { type = string }
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "admin_username" { type = string }
variable "admin_password" { type = string }
variable "sku_name" { type = string }
variable "storage_mb" { type = number }
variable "version_pg" { type = string }
variable "delegated_subnet_id" { type = string }
variable "private_dns_zone_id" { type = string }
variable "tags" { type = map(string) }

resource "azurerm_postgresql_flexible_server" "this" {
  name                   = var.name
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.version_pg
  administrator_login    = var.admin_username
  administrator_password = var.admin_password
  zone                   = "1"
  storage_mb             = var.storage_mb
  sku_name               = var.sku_name
  delegated_subnet_id    = var.delegated_subnet_id
  private_dns_zone_id    = var.private_dns_zone_id

  tags = var.tags
}

variable "databases" {
  type    = list(string)
  default = []
}

resource "azurerm_postgresql_flexible_server_database" "dbs" {
  for_each  = toset(var.databases)
  name      = each.key
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

output "id" { value = azurerm_postgresql_flexible_server.this.id }
output "fqdn" { value = azurerm_postgresql_flexible_server.this.fqdn }
output "database_names" { value = [for db in azurerm_postgresql_flexible_server_database.dbs : db.name] }
