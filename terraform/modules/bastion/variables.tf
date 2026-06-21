variable "name" {
  type        = string
  description = "Name of the Bastion host"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "virtual_network_id" {
  type        = string
  description = "ID of the Virtual Network (required for Developer SKU)"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the bastion host"
  default     = {}
}
