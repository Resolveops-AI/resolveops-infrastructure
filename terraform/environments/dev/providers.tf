terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Kubernetes provider configured against the ResolveOps AKS cluster.
# host/token/ca cert are read from the AKS resource after it is created.
provider "kubernetes" {
  host = module.aks.kube_config_host

  client_certificate     = base64decode(module.aks.kube_config_client_certificate)
  client_key             = base64decode(module.aks.kube_config_client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config_cluster_ca_certificate)
}
