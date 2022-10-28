terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "challenge" {
  name     = "${var.name}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "challenge" {
  name                = "${var.name}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.challenge.location
  resource_group_name = azurerm_resource_group.challenge.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.challenge.name
  virtual_network_name = azurerm_virtual_network.challenge.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "challenge-ip" {
  name                = "pip-challenge"
  resource_group_name = azurerm_resource_group.challenge.name
  location            = azurerm_resource_group.challenge.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "challenge" {
  name                = "${var.name}-nic"
  location            = azurerm_resource_group.challenge.location
  resource_group_name = azurerm_resource_group.challenge.name

  ip_configuration {
    name                          = "challengeconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.challenge-ip.id
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "challenge-nsg" {
  name                = "challenge-nsg"
  location            = azurerm_resource_group.challenge.location
  resource_group_name = azurerm_resource_group.challenge.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "200.158.169.179"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "200.158.169.179"
    destination_address_prefix = "*"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "challenge-association" {
  network_interface_id      = azurerm_network_interface.challenge.id
  network_security_group_id = azurerm_network_security_group.challenge-nsg.id
}

resource "azurerm_virtual_machine" "challenge" {
  name                  = "${var.name}-vm"
  location              = azurerm_resource_group.challenge.location
  resource_group_name   = azurerm_resource_group.challenge.name
  network_interface_ids = [azurerm_network_interface.challenge.id]
  vm_size               = "Standard_DS1_v2"

  

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "challenge-devops"
    admin_username = "azroot"
    admin_password = "seguro@12345"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
  
}