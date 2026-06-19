# dev environment — Terraform scaffold
# ⚠️ This is a scaffold. No real Terraform code currently exists.
# Full implementation is a future infrastructure milestone.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # backend "azurerm" {
  #   resource_group_name  = "resolveops-tfstate-rg"
  #   storage_account_name = "resolveopsaifstate"
  #   container_name       = "tfstate"
  #   key                  = "dev.terraform.tfstate"
  # }
}

# TODO: Implement dev environment resources using modules
# module "aks" {
#   source              = "../../modules/aks"
#   cluster_name        = "resolveops-ai-dev"
#   resource_group_name = var.resource_group_name
#   location            = var.location
# }
