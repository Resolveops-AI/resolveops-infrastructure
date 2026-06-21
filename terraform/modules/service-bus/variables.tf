variable "name" {
  type        = string
  description = "The name of the Service Bus namespace."
}

variable "location" {
  type        = string
  description = "The location of the Service Bus namespace."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "sku" {
  type        = string
  description = "The SKU of the Service Bus namespace (Basic, Standard, Premium)."
  default     = "Standard"
}

variable "queue_names" {
  type        = list(string)
  description = "List of queue names to create."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources."
  default     = {}
}
