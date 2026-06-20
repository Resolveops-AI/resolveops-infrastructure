variable "namespaces" {
  type        = list(string)
  description = "List of Kubernetes namespace names to create."
}

variable "labels" {
  type        = map(string)
  description = "Additional labels to apply to all namespaces."
  default     = {}
}

variable "annotations" {
  type        = map(string)
  description = "Annotations to apply to all namespaces."
  default     = {}
}
