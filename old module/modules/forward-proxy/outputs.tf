output "proxy_public_ip" {
  description = "Proxy server public IP"
  value       = azurerm_public_ip.proxy_public_ip.ip_address
}

output "proxy_private_ip" {
  description = "Proxy server private IP"
  value       = azurerm_network_interface.proxy.ip_configuration[0].private_ip_address
}
