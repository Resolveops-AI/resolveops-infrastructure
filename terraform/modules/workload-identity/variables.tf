variable "name" {
  type        = string
  description = "Name of the User Assigned Identity"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "oidc_issuer_url" {
  type        = string
  description = "OIDC issuer URL from AKS"
}

variable "service_account_namespace" {
  type        = string
  description = "Kubernetes namespace for the service account"
}

variable "service_account_name" {
  type        = string
  description = "Kubernetes service account name"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the User Assigned Identity"
  default     = {}
}
