terraform {
  backend "azurerm" {
    resource_group_name  = "rg-resolveops-tfstate"
    storage_account_name = "stresolveopstfstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
    use_oidc             = true
  }
}
