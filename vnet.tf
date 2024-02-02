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
    environment = "Terraform BYON with firewall"
  }
}

locals {
  vnet_resource_group_name = var.use_existing_resource_group ? var.resource_group_name : "${var.resource_group_name}-vnet"
}

# Create resource group using local.vnet_resource_group_name and var.resource_group_region
resource "azurerm_resource_group" "wiz_aks_vnet" {
  count    = var.use_existing_resource_group ? 0 : 1
  name     = local.vnet_resource_group_name
  location = var.resource_group_region

  tags = {
    environment = "Terraform BYON with firewall"
  }
}

locals {
  is_proxy = var.proxy_setup != "none"
}

# Create VPC with subnet using var.vpc_name
resource "azurerm_virtual_network" "wiz_aks" {
  name                = var.vnet_name
  address_space       = [var.vnet_cidr]
  location            = var.resource_group_region
  resource_group_name = local.vnet_resource_group_name
  depends_on          = [azurerm_resource_group.wiz_aks_vnet]

  tags = {
    environment = "Terraform BYON with firewall"
  }
}
