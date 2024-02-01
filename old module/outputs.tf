output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "vnet_id" {
  value = azurerm_virtual_network.wiz_aks.id
}

output "vnet_cidr" {
  value = azurerm_virtual_network.wiz_aks.address_space[0]
}

output "subnet_id" {
  description = "Bring-Your-Own-Network subnet ID"
  value       = azurerm_subnet.wiz_aks_subnet.id
}

output "proxy_private_ip" {
  description = "Proxy server private IP"
  value       = local.proxy_private_ip
}

output "proxy_ip" {
  description = "Proxy server public IP"
  value       = local.proxy_public_ip
}
