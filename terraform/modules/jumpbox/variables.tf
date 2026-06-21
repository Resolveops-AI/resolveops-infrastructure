variable "name" {
  type        = string
  description = "Name of the jumpbox VM"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the VM"
}

variable "vm_size" {
  type        = string
  description = "Size of the VM"
  default     = "Standard_B1s"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM"
  default     = "resolveopsadmin"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "SSH public key for the admin user"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the jumpbox"
  default     = {}
}
