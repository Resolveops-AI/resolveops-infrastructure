variable "name" {
  type        = string
  description = "Name of the cognitive services account"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "sku_name" {
  type        = string
  description = "SKU Name"
  default     = "S0"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the cognitive services account"
  default     = {}
}

variable "deployments" {
  description = "Map of cognitive service deployments"
  type = map(object({
    name = string
    model = object({
      format  = string
      name    = string
      version = string
    })
    scale = object({
      type     = string
      capacity = number
    })
  }))
  default = {}
}
