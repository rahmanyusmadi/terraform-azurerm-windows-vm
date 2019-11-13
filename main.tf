provider "azurerm" {}

data "azurerm_resource_group" "main" {
  name = "rahman-terraform-azurerm-windows"
}
