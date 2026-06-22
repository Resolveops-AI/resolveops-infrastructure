data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "this" {
  # checkov:skip=CKV_AZURE_232: Single default node pool by design — no separate user pool needed for this workload size
  # checkov:skip=CKV_AZURE_141: Local account kept enabled for initial cluster bootstrap; AAD RBAC can be layered later

  # checkov:skip=CKV_AZURE_168: Node pool size is Standard_B2ps_v2 which does not support 50 pods with Azure CNI

  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name

  kubernetes_version        = var.kubernetes_version
  private_cluster_enabled   = var.private_cluster_enabled
  automatic_upgrade_channel = "stable"
  local_account_disabled    = false
  azure_policy_enabled      = true

  default_node_pool {
    name           = "default"
    node_count     = var.node_count
    vm_size        = var.node_vm_size
    vnet_subnet_id = var.vnet_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = var.tags
}
