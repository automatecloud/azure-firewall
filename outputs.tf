output "subscription_id" {
  value = var.subscription_id
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