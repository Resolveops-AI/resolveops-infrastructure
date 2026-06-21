location            = "westus2"
resource_group_name = "Sathvik-RG"

vnet_name          = "vnet-resolveops-platform"
vnet_address_space = ["172.16.0.0/16"]

subnets = {
  "resolveops-aks"         = { address_prefixes = ["172.16.1.0/24"], service_endpoints = ["Microsoft.KeyVault"] }
  "appgw"                  = { address_prefixes = ["172.16.3.0/24"] }
  "snet-private-endpoints" = { address_prefixes = ["172.16.4.0/24"] }
  "AzureBastionSubnet"     = { address_prefixes = ["172.16.5.0/24"] }
  "jumpbox"                = { address_prefixes = ["172.16.6.0/24"] }
}

acr_name                     = "resolveopsacr01"
log_analytics_workspace_name = "law-resolveops-platform"
key_vault_name               = "resolveops-kv-01"
storage_account_name         = "resolveopssa01"

resolveops_aks_name  = "resolveops-aks-01"
resolveops_namespace = "resolveops"

quickhaul_dev_namespace  = "quickhaul-dev"
quickhaul_prod_namespace = "quickhaul-prod"
argocd_namespace         = "argocd"
monitoring_namespace     = "monitoring"

# Azure AI Service (ResolveOps AI)
ai_service_name = "resolveops-ai-01"
ai_sku_name     = "S0"
ai_location     = "westus2"

workload_identity_name            = "id-resolveops-workload"
workload_identity_service_account = "resolveops-workload-sa"

tags = {
  Project = "resolveops"
  Owner   = "platform-team"
}

authorized_ip_ranges = ["157.51.232.45/32"]
