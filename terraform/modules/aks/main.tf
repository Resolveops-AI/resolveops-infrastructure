data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "this" {
  # checkov:skip=CKV_AZURE_232: Single default node pool by design — no separate user pool needed for this workload size

  # checkov:skip=CKV_AZURE_168: Node pool size is Standard_B2ps_v2 which does not support 50 pods with Azure CNI

  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name

  kubernetes_version        = var.kubernetes_version
  private_cluster_enabled   = var.private_cluster_enabled
  automatic_upgrade_channel = "stable"
  local_account_disabled    = var.local_account_disabled
  azure_policy_enabled      = true

  default_node_pool {
    name                         = "systempool"
    vm_size                      = var.system_node_vm_size
    vnet_subnet_id               = var.vnet_subnet_id
    auto_scaling_enabled         = true
    min_count                    = var.system_node_min_count
    max_count                    = var.system_node_max_count
    max_pods                     = 30
    only_critical_addons_enabled = var.enable_system_pool_taint
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

resource "azurerm_kubernetes_cluster_node_pool" "userpool" {
  # checkov:skip=CKV_AZURE_168: Max pods kept at 30 due to node size and subnet size constraints
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_node_vm_size
  vnet_subnet_id        = var.vnet_subnet_id
  auto_scaling_enabled  = true
  min_count             = var.user_node_min_count
  max_count             = var.user_node_max_count
  max_pods              = 30
  mode                  = "User"
  tags                  = var.tags
}