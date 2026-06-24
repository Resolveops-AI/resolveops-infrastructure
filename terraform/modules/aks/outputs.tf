output "id" {
  value       = azurerm_kubernetes_cluster.this.id
  description = "The ID of the AKS cluster"
}

output "name" {
  value       = azurerm_kubernetes_cluster.this.name
  description = "The name of the AKS cluster"
}

output "kubelet_identity_object_id" {
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  description = "The object ID of the kubelet identity"
}

output "oidc_issuer_url" {
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
  description = "The OIDC issuer URL for workload identity federation"
}

output "kube_config_host" {
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  description = "The Kubernetes API server host URL."
  sensitive   = true
}

output "kube_config_client_certificate" {
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
  description = "Base64 encoded client certificate."
  sensitive   = true
}

output "kube_config_client_key" {
  value       = azurerm_kubernetes_cluster.this.kube_config[0].client_key
  description = "Base64 encoded client key."
  sensitive   = true
}

output "kube_config_cluster_ca_certificate" {
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  description = "Base64 encoded cluster CA certificate."
  sensitive   = true
}

output "system_node_pool_name" {
  value       = azurerm_kubernetes_cluster.this.default_node_pool[0].name
  description = "The name of the system node pool."
}

output "user_node_pool_name" {
  value       = azurerm_kubernetes_cluster_node_pool.userpool.name
  description = "The name of the user node pool."
}

output "ingress_application_gateway_identity_object_id" {
  value       = azurerm_kubernetes_cluster.this.ingress_application_gateway_identity[0].object_id
  description = "The object ID of the AGIC identity"
}
