provider "azurerm" {}

data "azurerm_resource_group" "main" {
  name = "rahman-terraform-azurerm-windows"
}

resource "azurerm_virtual_network" "main" {
    name                = "rahman-terraform-azurerm-windows"
    address_space       = ["10.0.0.0/16"]
    location            = data.azurerm_resource_group.main.location
    resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
    name                 = "rahman-terraform-azurerm-windows"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefix       = "10.0.2.0/24"
}
