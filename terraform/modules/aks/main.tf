resource "azurerm_kubernetes_cluster" "this" {
  # checkov:skip=CKV_AZURE_117: Skipped for low-cost demo deployment - customer-managed keys are too expensive
  # checkov:skip=CKV_AZURE_115: Skipped for low-cost demo deployment - private cluster is not needed for demo
  # checkov:skip=CKV_AZURE_227: Skipped for low-cost demo deployment - host encryption is not needed for demo
  # checkov:skip=CKV_AZURE_170: Skipped for low-cost demo deployment - paid SKU (SLA) is not needed for demo
  # checkov:skip=CKV_AZURE_226: Skipped for low-cost demo deployment - ephemeral OS disks are not needed for demo

  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  kubernetes_version = var.kubernetes_version

  # Enable automatic patch upgrades
  automatic_upgrade_channel = "patch"

  # Disable local admin account for improved security
  local_account_disabled = true

  default_node_pool {
    name                 = "system"
    vm_size              = var.system_node_vm_size
    vnet_subnet_id       = var.vnet_subnet_id
    auto_scaling_enabled = var.system_node_auto_scaling
    min_count            = var.system_node_min_count
    max_count            = var.system_node_max_count
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

  # Key Vault CSI secret rotation
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  tags = var.tags
}
