# Terraform scaffold — AKS module
# ⚠️ This is a scaffold. No real Terraform code currently exists.
# Full Terraform implementation is a future infrastructure milestone.

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "node_count" {
  description = "Initial node pool count"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Node VM size"
  type        = string
  default     = "Standard_D2s_v3"
}

# TODO: Implement AKS cluster resource
# resource "azurerm_kubernetes_cluster" "resolveops" { ... }
