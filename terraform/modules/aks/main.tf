resource "azurerm_kubernetes_cluster" "this" {

  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  kubernetes_version = var.kubernetes_version

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
}
