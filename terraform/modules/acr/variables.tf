variable "name" {
  type        = string
  description = "Name of the container registry"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "sku" {
  type        = string
  description = "SKU for the container registry"
  default     = "Basic"
}

variable "admin_enabled" {
  type        = bool
  description = "Enable admin user for the container registry"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the ACR"
  default     = {}
}
