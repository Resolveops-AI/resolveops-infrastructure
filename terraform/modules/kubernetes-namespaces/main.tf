# Creates one Kubernetes namespace per entry in var.namespaces.
# Terraform only provisions the namespace objects; application workloads
# are deployed by Helm / Argo CD.
resource "kubernetes_namespace_v1" "namespaces" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.value

    labels = merge(var.labels, {
      "managed-by" = "terraform"
    })

    annotations = var.annotations
  }
}
