output "namespace_names" {
  value       = [for ns in kubernetes_namespace_v1.namespaces : ns.metadata[0].name]
  description = "List of namespace names created by this module."
}

output "namespace_map" {
  value       = { for k, ns in kubernetes_namespace_v1.namespaces : k => ns.metadata[0].name }
  description = "Map of namespace key to namespace name."
}
