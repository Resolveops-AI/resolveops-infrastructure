variable "enabled" {
  type        = bool
  description = "Enable Service Bus"
  default     = false
}

variable "name" {
  type        = string
  description = "Name of the Service Bus namespace"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Service Bus"
  default     = {}
}
