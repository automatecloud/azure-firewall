provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  environment     = var.azure_china ? "China" : "Public"
}

data "azurerm_client_config" "current" {
}

# Create resource group using var.resource_group_name and var.resource_group_region
resource "azurerm_resource_group" "wiz_aks" {
  count    = var.use_existing_resource_group ? 0 : 1
  name     = var.resource_group_name
  location = var.resource_group_region

  tags = {
    environment = "Terraform BYON with proxy server"
  }
}