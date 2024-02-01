# Outpost Virtual Network

Creates the following:

1. Resource group for Wiz to create resources in
2. Resource group for Vnet resources to be created in
2. VPC for the AKS cluster with single subnet created in it
3. 1 Subnets for the AKS cluster nodes
4. When using proxy setup an additional subnet is created for proxy resources

## Variables

| Variable                                                 | Mandatory? | Default Value                      |
| -------------------------------------------------------- |:----------:| ---------------------------------- |
| var.subscription_id                                      | yes        |                                    |
| var.resource_group_name                                  | yes        |                                    |
| var.resource_group_region                                | yes        |                                    |
| var.proxy_setup                                          | no         | "none", "reverse", "forward"       |
| var.use_existing_resource_group                          | no         | false                              |
| var.vnet_name                                            | no         | wiz_vnet                           |
| var.vnet_cidr                                            | no         | "10.1.0.0/16"                      |
| var.subnet_aks_cidr                                      | no         | "10.1.0.0/18"                      |
| var.subnet_public_cidr                                   | no         | "10.1.64.0/24"                     |
| var.azure_china                                          | no         | false                              |
| var.aks_subnet_private_endpoint_network_policies_enabled | no         | true, disable for private clusters |

## Outputs

* subscription_id
* resource_group_name
* vnet_id
* subnet_id
* proxy_ip
