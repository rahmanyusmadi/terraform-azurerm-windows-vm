provider "azurerm" {}

data "azurerm_client_config" "main" {}

resource "random_password" "password" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "azurerm_resource_group" "main" {
  name     = var.prefix
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet1"
  address_space       = var.address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    label = var.prefix
  }
}

resource "azurerm_subnet" "main" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = var.address_prefix
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
  domain_name_label   = var.prefix

  tags = {
    label = var.prefix
  }
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = {
    label = var.prefix
  }
}

resource "azurerm_network_security_rule" "remote_desktop" {
  name                        = "Remote Access"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "${var.my_public_ip_address}/32"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}


resource "azurerm_network_interface" "main" {
  name                      = "${var.prefix}-nic1"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  network_security_group_id = azurerm_network_security_group.main.id

  ip_configuration {
    name                          = "${var.prefix}-config1"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = {
    label = var.prefix
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm1"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = var.vm_size

  storage_os_disk {
    name              = "${var.prefix}-disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = var.image_version
  }

  os_profile {
    computer_name  = "${var.prefix}"
    admin_username = "${var.prefix}-user"
    admin_password = random_password.password.result
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  tags = {
    label = var.prefix
  }
}

resource "azurerm_key_vault" "main" {
  name                        = "${var.prefix}-vault"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.main.tenant_id

  sku_name = "standard"

  tags = {
    label = var.prefix
  }
}

resource "azurerm_key_vault_secret" "password" {
  name         = "${prefix}-password"
  value        = random_password.password.result
  key_vault_id = "${azurerm_key_vault.main.id}"

  tags = {
    label = var.prefix
  }
}
