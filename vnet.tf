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

locals {
  vnet_resource_group_name = var.use_existing_resource_group ? var.resource_group_name : "${var.resource_group_name}-vnet"
}

resource "azurerm_resource_group" "wiz_aks_vnet" {
  count    = var.use_existing_resource_group ? 0 : 1
  name     = local.vnet_resource_group_name
  location = var.resource_group_region

  tags = {
    environment = "Terraform BYON with proxy server"
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
    environment = "Terraform BYON with proxy server"
  }
}

locals {
  subnet_service_endpoints = concat(
    [
      "Microsoft.KeyVault",
      "Microsoft.ServiceBus",
      "Microsoft.Storage.Global"
    ],
    var.azure_china ? [] : ["Microsoft.AzureActiveDirectory", "Microsoft.ContainerRegistry"]
  )
}

resource "azurerm_subnet" "wiz_aks_subnet" {
  name                                      = "${var.vnet_name}AKSSubnet"
  virtual_network_name                      = var.vnet_name
  address_prefixes                          = [var.subnet_aks_cidr]
  resource_group_name                       = local.vnet_resource_group_name
  service_endpoints                         = local.subnet_service_endpoints
  private_endpoint_network_policies_enabled = var.aks_subnet_private_endpoint_network_policies_enabled
  depends_on                                = [azurerm_virtual_network.wiz_aks]
}

resource "azurerm_subnet" "wiz_aks_public" {
  count                = local.is_proxy ? 1 : 0
  name                 = var.proxy_setup == "reverse" ? "AzureFirewallSubnet" : "${var.vnet_name}PublicSubnet"
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_public_cidr]
  resource_group_name  = local.vnet_resource_group_name
  depends_on           = [azurerm_virtual_network.wiz_aks]
}

# Create proxy
module "reverse_proxy" {
  count  = var.proxy_setup == "reverse" ? 1 : 0
  source = "./modules/reverse-proxy"

  resource_group_region = var.resource_group_region
  resource_group_name   = local.vnet_resource_group_name
  subnet_id             = azurerm_subnet.wiz_aks_public[0].id
  aks_subnet_id         = azurerm_subnet.wiz_aks_subnet.id
  name_prefix           = var.vnet_name

  depends_on = [azurerm_virtual_network.wiz_aks]
}

module "forward_proxy" {
  count  = var.proxy_setup == "forward" ? 1 : 0
  source = "./modules/forward-proxy"

  resource_group_region = var.resource_group_region
  resource_group_name   = local.vnet_resource_group_name
  subnet_id             = azurerm_subnet.wiz_aks_public[0].id
  aks_subnet_id         = azurerm_subnet.wiz_aks_subnet.id
  name_prefix           = var.vnet_name

  depends_on = [azurerm_virtual_network.wiz_aks]
}

locals {
  proxy_private_ip = {
    "reverse" = var.proxy_setup == "reverse" ? module.reverse_proxy[0].proxy_private_ip : ""
    "forward" = var.proxy_setup == "forward" ? module.forward_proxy[0].proxy_private_ip : ""
  }

  proxy_public_ip = {
    "reverse" = var.proxy_setup == "reverse" ? module.reverse_proxy[0].proxy_public_ip : ""
    "forward" = var.proxy_setup == "forward" ? module.forward_proxy[0].proxy_public_ip : ""
  }
}
