
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

resource "azurerm_network_interface" "proxy" {
  name                 = "${var.name_prefix}-proxy-nic"
  location             = var.resource_group_region
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "proxyipconfiguration1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.proxy_public_ip.id
  }

  tags = {
    environment = "Terraform BYON with proxy server"
  }
}

resource "azurerm_virtual_machine" "proxy" {
  name                             = "${var.name_prefix}-proxy"
  location                         = var.resource_group_region
  resource_group_name              = var.resource_group_name
  network_interface_ids            = [azurerm_network_interface.proxy.id]
  vm_size                          = "Standard_DS1_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "osdisk1"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "ubuntu"
    admin_username = "rootuser"
    admin_password = "Password1234!"
    custom_data    = <<EOF1
MIME-Version: 1.0
Content-Type:text/x-shellscript; charset="us-ascii"

#!/bin/bash

cat << EOF >> /.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDW7Z2SxvzRHpjWRn0jsKAidI3bqjO1wKR9vZMSJu0wSwPGxiSLJM21+zmRr29qx41JjQ5Y+kVM6tlusxmqeZ9JHvKauTrNlHx9cHnjWAvN8joN70UGJBJWqLOCBAxfmKCI4RB+qS3u8uhTac1KRJ52uoGlUEaKZqPU9o4rkeIJ34Sf9AitchHeuJqiiiiPZ+HvThznr3SGbCCmhwgjzG/CTQGkJjhU5s84k3x/I1vEHji5INjreusPFjJ8Kv141k0piT3aEO6TDR3c/pVXMxYbRk3GorbVx4yOGruNKwtNbD9GpdNzDW7y7JP3DPRCkP4uBGf4t52VhvCXcO5OnKzv eyal_developer_key
EOF

# Apply the latest security patches
apt update -y --security

# Install Squid
apt install -y squid

# Create Squid Config
mkdir -p /etc/squid
mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
cat << EOF >> /etc/squid/squid.conf
cache deny all

# Log format and rotation
logformat squid %ts.%03tu %6tr %>a %Ss/%03>Hs %<st %rm %ru %ssl::>sni %Sh/%<a %mt
logfile_rotate 10
debug_options rotate=10

# Handle HTTP requests
http_port 3128

http_access allow all
# http_access deny all
EOF

# Start Squid
systemctl start squid || service squid start
/usr/sbin/squid -k parse && /usr/sbin/squid -k reconfigure

    EOF1
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}

resource "azurerm_network_security_group" "wiz_aks_private_nsg" {
  name                = "${var.name_prefix}-nsg"
  location            = var.resource_group_region
  resource_group_name = var.resource_group_name

  // https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-faq#what-ports-do-i-need-to-open-on-the-firewall--
  security_rule {
    name                       = "AllowServiceBusCommunicationOutbound"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
    destination_address_prefix = "ServiceBus"
    destination_port_ranges    = ["5671","5672"] // AMQP
  }

  security_rule {
    name                       = "deny-internet-outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = {
    environment = "Terraform BYON with proxy server"
  }
}

resource "azurerm_subnet_network_security_group_association" "wiz_aks_private_nsg_association" {
  subnet_id                 = var.aks_subnet_id
  network_security_group_id = azurerm_network_security_group.wiz_aks_private_nsg.id
}
