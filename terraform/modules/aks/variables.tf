variable "cluster_name" {
  type        = string
  description = "Name of the AKS cluster"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version to use"
  default     = null # Use Azure default
}

variable "vnet_subnet_id" {
  type        = string
  description = "Subnet ID for the default node pool"
}

variable "system_node_vm_size" {
  type        = string
  description = "VM size for the system node pool"
  default     = "Standard_DS2_v2"
}

variable "system_node_auto_scaling" {
  type        = bool
  description = "Enable auto scaling for system node pool"
  default     = true
}

variable "system_node_min_count" {
  type        = number
  description = "Min node count for system pool"
  default     = 1
}

variable "system_node_max_count" {
  type        = number
  description = "Max node count for system pool"
  default     = 3
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "ID of the Log Analytics workspace for monitoring"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the AKS resources"
  default     = {}
}

# Note: enable_agic and appgw_gateway_id removed — the managed AGIC addon is not
# supported on private AKS clusters. AGIC is installed via Helm post-provisioning.

variable "private_cluster_enabled" {
  type        = bool
  description = "Enable private cluster (satisfies org MG policy)"
  default     = true
}

variable "authorized_ip_ranges" {
  type        = list(string)
  description = "Authorized IP ranges for API server access"
  default     = []
}

variable "user_node_vm_size" {
  type        = string
  description = "VM size for the user node pool"
  default     = "Standard_DS2_v2"
}

variable "user_node_count" {
  type        = number
  description = "Node count for the user node pool"
  default     = 1
}

variable "service_cidr" {
  type        = string
  description = "CIDR range for Kubernetes services (must not overlap with VNet)"
  default     = "10.0.0.0/16"
}

variable "dns_service_ip" {
  type        = string
  description = "IP address for Kubernetes DNS service (must be inside service_cidr)"
  default     = "10.0.0.10"
}
