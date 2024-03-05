provider "azurerm" {
  features {}
}

locals {
  port     = "7860"
  username = "a1111root"

  service = templatefile("${path.module}/service.tpl", {
    user = local.username
  })

  custom_data = templatefile("${path.module}/custom-data.tpl", {
    service = local.service,
    user    = local.username
  })
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.deployment_name}-${var.location}"
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.deployment_name}-${var.location}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "snet-${var.deployment_name}-${var.location}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.0.0/16"]
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_public_ip" "this" {
  name                = "pip-${var.deployment_name}-${var.location}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.deployment_name}-${var.location}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTO"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = local.port
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "this" {
  name                = "nic-${var.deployment_name}-${var.location}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "ipc-${var.deployment_name}-${var.location}"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_linux_virtual_machine" "this" {
  name                  = "vm-${var.deployment_name}-${var.location}"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.this.id]
  size                  = "Standard_NC6s_v3"
  custom_data           = base64encode(local.custom_data)

  os_disk {
    name                 = "disk-${var.deployment_name}-${var.location}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  computer_name                   = "vm-${var.deployment_name}-${var.location}"
  admin_username                  = local.username
  disable_password_authentication = true

  admin_ssh_key {
    username   = local.username
    public_key = tls_private_key.this.public_key_openssh
  }
}
