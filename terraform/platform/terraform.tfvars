location            = "eastus"
resource_group_name = "resolveops-platform-rg-01"

vnet_name          = "vnet-resolveops-platform"
vnet_address_space = ["172.16.0.0/16"]

subnets = {
  "snet-aks-resolveops"    = { address_prefixes = ["172.16.1.0/24"], service_endpoints = ["Microsoft.KeyVault"] }
  "snet-aks-quickhaul"     = { address_prefixes = ["172.16.2.0/24"], service_endpoints = ["Microsoft.KeyVault"] }
  "snet-appgateway"        = { address_prefixes = ["172.16.3.0/24"] }
  "snet-private-endpoints" = { address_prefixes = ["172.16.4.0/24"] }
  "AzureBastionSubnet"     = { address_prefixes = ["172.16.5.0/24"] }
}

acr_name                     = "resolveopsacr01"
log_analytics_workspace_name = "law-resolveops-platform"
key_vault_name               = "resolveops-kv-01"
storage_account_name         = "resolveopssa01"

resolveops_aks_name  = "resolveops-aks-01"
resolveops_namespace = "resolveops"

quickhaul_aks_name       = "quickhaul-aks-01"
quickhaul_dev_namespace  = "quickhaul-dev"
quickhaul_prod_namespace = "quickhaul-prod"
argocd_namespace         = "argocd"
monitoring_namespace     = "monitoring"

workload_identity_name            = "id-resolveops-workload"
workload_identity_service_account = "resolveops-workload-sa"

tags = {
  Project = "resolveops"
  Owner   = "platform-team"
}

authorized_ip_ranges = ["157.51.232.45/32"]
