location            = "centralindia"
resource_group_name = "sathvik-rg"

vnet_name          = "resolveops-vnet"
vnet_address_space = ["172.16.0.0/16"]

subnets = {
  "resolveops-aks"         = { address_prefixes = ["172.16.1.0/24"], service_endpoints = ["Microsoft.KeyVault"] }
  "appgw"                  = { address_prefixes = ["172.16.3.0/24"] }
  "snet-private-endpoints" = { address_prefixes = ["172.16.4.0/24"] }
  "AzureBastionSubnet"     = { address_prefixes = ["172.16.5.0/24"] }
  "jumpbox"                = { address_prefixes = ["172.16.6.0/24"] }
}

acr_name                     = "resolveopsacr03"
log_analytics_workspace_name = "resolveops-law"
key_vault_name               = "sathvik-kv-03"
storage_account_name         = "resolveopssa03"

resolveops_aks_name  = "resolveops-aks-02"
resolveops_namespace = "resolveops"

quickhaul_dev_namespace  = "quickhaul-dev"
quickhaul_prod_namespace = "quickhaul-prod"
argocd_namespace         = "argocd"
monitoring_namespace     = "monitoring"

# Azure AI Service (ResolveOps AI)
ai_service_name = "resolveops-ai-03"
ai_sku_name     = "S0"
ai_location     = "southindia"

workload_identity_name            = "id-resolveops-workload"
workload_identity_service_account = "resolveops-workload-sa"

tags = {
  Project = "resolveops"
  Owner   = "platform-team"
}

authorized_ip_ranges = ["157.51.232.45/32"]

service_bus_namespace_name = "resolveops-sb-02"
service_bus_sku            = "Standard"

service_bus_queue_names = [
  "github-sync-requested",
  "azure-sync-requested",
  "aws-sync-requested",
  "resource-scan-completed",
  "rca-requested",
  "rca-completed",
  "notification-requested",
  "diagram-generation-requested"
]

resolveops_aks_admin_group_object_ids = ["1b351c30-6447-44b5-9ff1-9297cb7aaf9f"]
resolveops_aks_local_account_disabled = true

# AKS Node Pools Configuration
system_node_vm_size      = "Standard_D4s_v3"
system_node_min_count    = 2
system_node_max_count    = 3
user_node_vm_size        = "Standard_DS3_v2"
user_node_min_count      = 1
user_node_max_count      = 3
enable_system_pool_taint = false