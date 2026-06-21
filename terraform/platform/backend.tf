terraform {
  backend "azurerm" {
    resource_group_name  = "Sathvik-RG"
    storage_account_name = "stsathviktfstate"
    container_name       = "tfstate"
    key                  = "platform.terraform.tfstate"
    use_oidc             = true
  }
}
