# azure-firewall
 using azure firewall with UDR for AKS

module "wiz_firewall" {
  source                = "git::https://github.com/automatecloud/azure-firewall"
  subscription_id       = "sub"
  resource_group_region = "eastus"
  resource_group_name   = "wiz-outpost-eastus"
  proxy_setup           = "reverse"
}

output "subscription_id" {
  value = module.wiz_cluster.subscription_id
}

output "resource_group_name" {
  value = module.wiz_cluster.resource_group_name
}

output "vnet_id" {
  value = module.wiz_cluster.vnet_id
}

output "subnet_id" {
  value = module.wiz_cluster.subnet_id
}

output "proxy_ip" {
  value = module.wiz_cluster.proxy_ip
}
