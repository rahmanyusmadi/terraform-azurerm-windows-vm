provider "azurerm" {}

data "azurerm_resource_group" "main" {
  name = "rahman-terraform-azurerm-windows"
}

resource "azurerm_virtual_network" "main" {
    name                = "vnet1"
    address_space       = ["10.0.0.0/16"]
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name

    tags = {
        label = "terraform-azurerm-windows"
    }
}

resource "azurerm_subnet" "main" {
    name                 = "subnet1"
    resource_group_name  = data.azurerm_resource_group.main.name
    virtual_network_name = data.azurerm_virtual_network.main.name
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "main" {
    name                         = "pip1"
    location                     = data.azurerm_resource_group.main.location
    resource_group_name          = data.azurerm_resource_group.main.name
    allocation_method            = "Dynamic"

    tags = {
        label = "terraform-azurerm-windows"
    }
}

resource "azurerm_network_security_group" "main" {
    name                = "nsg1"
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name
    
    tags = {
        label = "terraform-azurerm-windows"
    }
}
