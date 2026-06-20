variable "name" {
  type        = string
  description = "Name of the Storage Account"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "replication_type" {
  type        = string
  description = "Replication type"
  default     = "LRS"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Storage Account"
  default     = {}
}
