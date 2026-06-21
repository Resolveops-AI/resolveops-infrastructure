data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "this" {
  # checkov:skip=CKV_AZURE_232: Due to strict 4-core regional quota, we must run user workloads on the system node pool

  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  kubernetes_version = var.kubernetes_version

  automatic_upgrade_channel = "patch"

  private_cluster_enabled = var.private_cluster_enabled

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  local_account_disabled = true

  azure_policy_enabled = true

  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_vm_size
    vnet_subnet_id               = var.vnet_subnet_id
    auto_scaling_enabled         = var.system_node_auto_scaling
    min_count                    = var.system_node_min_count
    max_count                    = var.system_node_max_count
    max_pods                     = 50
    only_critical_addons_enabled = true
    upgrade_settings {
      max_surge = "0"
    }
  }

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  dynamic "ingress_application_gateway" {
    for_each = var.enable_agic ? [1] : []
    content {
      gateway_id = var.appgw_gateway_id
    }
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true


  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_node_vm_size
  vnet_subnet_id        = var.vnet_subnet_id
  node_count            = var.user_node_count
  max_pods              = 50
  tags                  = var.tags

  upgrade_settings {
    max_surge = "0"
  }
}
