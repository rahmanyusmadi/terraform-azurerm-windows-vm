provider "azurerm" {}

variable "password" {}

variable "location" {}

variable "prefix" {}

resource "azurerm_resource_group" "main" {
  name = var.prefix
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name        = "vnet1"
  address_space     = ["10.0.0.0/16"]
  location      = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    label = var.prefix
  }
}

resource "azurerm_subnet" "main" {
  name         = "subnet1"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix     = "10.0.2.0/24"
}

resource "azurerm_public_ip" "main" {
  name             = "pip1"
  location           = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  allocation_method      = "Dynamic"
  domain_name_label = var.prefix

  tags = {
    label = var.prefix
  }
}

resource "azurerm_network_security_group" "main" {
  name        = "nsg1"
  location      = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = {
    label = var.prefix
  }
}

resource "azurerm_network_interface" "main" {
  name            = "nic1"
  location          = "eastus"
  resource_group_name     = azurerm_resource_group.main.name
  network_security_group_id   = azurerm_network_security_group.main.id

  ip_configuration {
    name              = "config1"
    subnet_id           = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id      = azurerm_public_ip.main.id
  }

  tags = {
    label = var.prefix
  }
}

resource "azurerm_virtual_machine" "main" {
  name          = "vm1"
  location        = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size         = "Standard_DS1_v2"

  storage_os_disk {
    name        = "disk1"
    caching       = "ReadWrite"
    create_option   = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer   = "Windows-10"
    sku     = "19h1-pro"
    version   = "latest"
  }

  os_profile {
    computer_name  = var.prefix
    admin_username = var.prefix
    admin_password = var.password
  }

  os_profile_windows_config {
  provision_vm_agent    = true
  enable_automatic_upgrades = true

  # Auto-Login's required to configure WinRM
  additional_unattend_config {
    pass     = "oobeSystem"
    component  = "Microsoft-Windows-Shell-Setup"
    setting_name = "AutoLogon"
    content    = "<AutoLogon><Password><Value>${var.password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.password}</Username></AutoLogon>"
  }

  }

  tags = {
    label = var.prefix
  }
}
