variable "name" {
  type        = string
  description = "Application Gateway name"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the Application Gateway"
}

variable "tags" {
  type    = map(string)
  default = {}
}
