# Microsoft AKS Mandatory FQDNs:
# ------------------------------
# based on: https://learn.microsoft.com/en-us/azure/aks/limit-egress-traffic
# https://learn.microsoft.com/en-us/azure/virtual-network/service-tags-overview#discover-service-tags-by-using-downloadable-json-files

# port      protocol  destination 
# 53, 1149  UDP       AzureCloud.<location>
# 9000      TCP       AzureCloud.<location>
# 123       UDP       ntp.ubuntu.com

# APIServerPublicIP                               HTTPS:443 # the cluster public IP (only known after cluster creation)
# *.hcp.<location>.azmk8s.io                      HTTPS:443
# mcr.microsoft.com                               HTTPS:443
# *.data.mcr.microsoft.com                        HTTPS:443
# management.azure.com                            HTTPS:443
# login.microsoftonline.com                       HTTPS:443
# packages.microsoft.com                          HTTPS:443
# acs-mirror.azureedge.net                        HTTPS:443
# security.ubuntu.com                             HTTP:80,HTTPS:443
# azure.archive.ubuntu.com                        HTTP:80,HTTPS:443
# changelogs.ubuntu.com                           HTTP:80,HTTPS:443
# motd.ubuntu.com                                 HTTPS:443

# Wiz Specific FQDNs:
# -------------------
# wiziopublic.azurecr.io                          HTTP:80,HTTPS:443
# wizio.azurecr.io                                HTTP:80,HTTPS:443
# *.blob.core.windows.net                         HTTP:80,HTTPS:443
# *datadoghq.com                                  HTTPS:10516,HTTPS:443
# *.s3.<backend region aws region>.amazonaws.com  HTTPS:443 (test-diskanalyzer-results-source-us-east-2.s3.us-east-2.amazonaws.com:443)

resource "azurerm_public_ip" "proxy_public_ip" {
  name                = "${var.name_prefix}-proxyPublicIP"
  location            = var.resource_group_region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  depends_on          = [var.subnet_id]

  tags = {
    environment = "Terraform BYON with proxy server"
  }
}

resource "azurerm_firewall_policy" "reverse_proxy" {
  name                = "${var.name_prefix}FirewallPolicy"
  location            = var.resource_group_region
  resource_group_name = var.resource_group_name

  dns {
    proxy_enabled = true
  }
}

# Policy rule collection group
resource "azurerm_firewall_policy_rule_collection_group" "reverse_proxy_rcp" {
  name               = "${var.name_prefix}FirewallRCG"
  firewall_policy_id = azurerm_firewall_policy.reverse_proxy.id
  priority           = 100

  application_rule_collection {
    name     = "aksfwar"
    priority = 202
    action   = "Allow"

    rule {
      name                  = "fqdn"
      source_addresses      = ["*"]
      destination_fqdn_tags = ["AzureKubernetesService"]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
    // the followng rules are based on:
    // https://learn.microsoft.com/en-us/azure/aks/limit-egress-traffic
    rule {
      name              = "APIServer"
      source_addresses  = ["*"]
      destination_fqdns = ["*.hcp.${var.resource_group_region}.azmk8s.io"]
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "MCR"
      source_addresses  = ["*"]
      destination_fqdns = ["mcr.miscrosoft.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "MCDStorage"
      source_addresses  = ["*"]
      destination_fqdns = ["*.data.mcr.miscrosoft.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "AzureAPI"
      source_addresses  = ["*"]
      destination_fqdns = ["management.azure.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "AADAuth"
      source_addresses  = ["*"]
      destination_fqdns = ["login.microsoftonline.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "MSPackages"
      source_addresses  = ["*"]
      destination_fqdns = ["packages.microsoft.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "MSMirror"
      source_addresses  = ["*"]
      destination_fqdns = ["acs-mirror.azureedge.net"]
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "Ubuntu"
      source_addresses  = ["*"]
      destination_fqdns = ["security.ubuntu.com", "azure.archive.ubuntu.com", "changelogs.ubuntu.com"]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name              = "Wiz ACRs"
      source_addresses  = ["*"]
      destination_fqdns = ["*.blob.core.windows.net"]
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "wiziopublic"
      source_addresses  = ["*"]
      destination_fqdns = ["wiziopublic.azurecr.io", "wizio.azurecr.io"]
      protocols {
        type = "Https"
        port = 443
      }
    }
    rule {
      name              = "datadoghq"
      source_addresses  = ["*"]
      destination_fqdns = ["*datadoghq.com"]
      protocols {
        type = "Https"
        port = 443
      }
      protocols {
        type = "Https"
        port = 10516
      }
    }
    rule {
      name              = "resutls-bucket"
      source_addresses  = ["*"]
      destination_fqdns = ["*.s3.us-east-2.amazonaws.com"]
      # destination_fqdns = ["*.s3.<backend region aws region>.amazonaws.com"]
      protocols {
        type = "Https"
        port = 443
      }
    }
  }

  network_rule_collection {
    name     = "aksfwnr"
    priority = 101
    action   = "Allow"

    rule {
      name                  = "apiudp"
      source_addresses      = ["*"]
      destination_ports     = ["53"]
      destination_addresses = ["AzureCloud.${var.resource_group_region}"]
      protocols             = ["UDP"]
    }

    rule {
      name                  = "apiudp2"
      source_addresses      = ["*"]
      destination_ports     = ["1149"]
      destination_addresses = ["AzureCloud.${var.resource_group_region}"]
      protocols             = ["UDP"]
    }

    rule {
      name                  = "apitcp"
      source_addresses      = ["*"]
      destination_ports     = ["9000"]
      destination_addresses = ["AzureCloud.${var.resource_group_region}"]
      protocols             = ["TCP"]
    }

    rule {
      name              = "time"
      source_addresses  = ["*"]
      destination_ports = ["123"]
      destination_fqdns = ["ntp.ubuntu.com"]
      protocols         = ["UDP"]
    }

    rule {
      name                  = "apiserver"
      source_addresses      = ["*"]
      destination_ports     = ["443"]
      destination_addresses = ["*"] # replace with Cluster's API server public IP
      protocols             = ["TCP"]
    }
  }
}

# Add firewall
resource "azurerm_firewall" "reverse_proxy" {
  name                = "${var.name_prefix}Firewall"
  location            = var.resource_group_region
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.reverse_proxy.id

  ip_configuration {
    name                 = "proxyNic"
    subnet_id            = var.subnet_id
    public_ip_address_id = azurerm_public_ip.proxy_public_ip.id
  }

  depends_on = [azurerm_firewall_policy_rule_collection_group.reverse_proxy_rcp]

  tags = {
    environment = "Terraform BYON with proxy server"
  }
}

# Create route tables to route traffic to proxy
resource "azurerm_route_table" "proxy_route_table" {
  name                = "${var.name_prefix}ProxyRouteTable"
  location            = var.resource_group_region
  resource_group_name = var.resource_group_name

  route {
    name                   = "clusterToProxy"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.reverse_proxy.ip_configuration[0].private_ip_address
  }

  route {
    name           = "proxyToInternet"
    address_prefix = "${azurerm_public_ip.proxy_public_ip.ip_address}/32"
    next_hop_type  = "Internet"
  }

  tags = {
    environment = "Terraform BYON with proxy server"
  }
}

# Associate route table with next hop to Firewall to the AKS subnet
resource "azurerm_subnet_route_table_association" "wiz_aks_private_rt_ass" {
  subnet_id      = var.aks_subnet_id
  route_table_id = azurerm_route_table.proxy_route_table.id
}
