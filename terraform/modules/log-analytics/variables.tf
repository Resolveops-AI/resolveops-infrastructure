variable "name" {
  type        = string
  description = "Name of the Log Analytics Workspace"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "sku" {
  type        = string
  description = "SKU for the Log Analytics Workspace"
  default     = "PerGB2018"
}

variable "retention_in_days" {
  type        = number
  description = "Retention period in days"
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Log Analytics Workspace"
  default     = {}
}
