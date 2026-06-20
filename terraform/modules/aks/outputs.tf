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
  description = "The OIDC issuer URL for the AKS cluster"
}

output "node_resource_group" {
  value       = azurerm_kubernetes_cluster.this.node_resource_group
  description = "The auto-generated Resource Group which contains the resources for this Managed Kubernetes Cluster."
}
