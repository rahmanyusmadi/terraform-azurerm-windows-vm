terraform {
  required_version = "~> 0.12.0"

  required_providers {
    azurerm = "~> 1.36.0"
  }
}

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

  delete_os_disk_on_termination = true

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
  
  /*
  identity {
    type         = "UserAssigned"
    identity_ids = [ data.azurerm_client_config.main.client_id ]
  }
  */

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

  access_policy {
    tenant_id = data.azurerm_client_config.main.tenant_id
    object_id = data.azurerm_client_config.main.object_id

    secret_permissions = [
      "get",
      "set",
      "delete",
    ]
  }

  tags = {
    label = var.prefix
  }
}

resource "azurerm_key_vault_secret" "password" {
  name         = "${var.prefix}-password"
  value        = random_password.password.result
  key_vault_id = "${azurerm_key_vault.main.id}"

  tags = {
    label = var.prefix
  }
}

/* auto-shutdown doesn't work at the moment. refer terraform-provider-azurerm issues with service/devtestlabs label
resource "azurerm_dev_test_lab" "main" {
  name                = "YourDevTestLab"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

}

resource "azurerm_dev_test_schedule" "main" {
  name                = "shutdown-compute-${var.prefix}-vm1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  lab_name            = azurerm_dev_test_lab.main.name
  
  status = "Enabled"

  daily_recurrence {
    time      = "0852"
  }

  time_zone_id = "Singapore Standard Time"
  task_type    = "ComputeVmShutdownTask"

  notification_settings {
  }

  tags = {
    label = var.prefix
  }
}
*/
  
resource "azurerm_template_deployment" "main" {
  name                = "${var.prefix}-template1"
  resource_group_name = azurerm_resource_group.main.name

  template_body = <<DEPLOY
{
    "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "location": {
            "type": "String",
            "defaultValue": "southeastasia"
        },
        "networkInterfaceName": {
            "type": "String",
            "defaultValue": "windows10nic"
        },
        "networkSecurityGroupName": {
            "type": "String",
            "defaultValue": "windows10-nsg"
        },
        "subnetName": {
            "type": "String",
            "defaultValue": "default"
        },
        "virtualNetworkName": {
            "type": "String",
            "defaultValue": "dockerlab-vnet"
        },
        "addressPrefixes": {
            "type": "Array",
            "defaultValue": [
                "10.0.0.0/24"
            ]
        },
        "subnets": {
            "type": "Array",
            "defaultValue": [
                {
                    "name": "default",
                    "properties": {
                        "addressPrefix": "10.0.0.0/24"
                    }
                }
            ]
        },
        "publicIpAddressName": {
            "type": "String",
            "defaultValue": "windows10-ip"
        },
        "publicIpAddressType": {
            "type": "String",
            "defaultValue": "Dynamic"
        },
        "domainNameLabel": {
            "type": "String"
        },
        "publicIpAddressSku": {
            "type": "String",
            "defaultValue": "Basic"
        },
        "virtualMachineName": {
            "type": "String",
            "defaultValue": "windows10"
        },
        "virtualMachineRG": {
            "type": "String",
            "defaultValue": "dockerlab-rg"
        },
        "osDiskType": {
            "type": "String",
            "defaultValue": "Premium_LRS"
        },
        "virtualMachineSize": {
            "type": "String",
            "defaultValue": "Standard_D2s_v3"
        },
        "adminUsername": {
            "type": "String",
            "defaultValue": "dockeruser"
        },
        "adminPassword": {
            "type": "SecureString"
        },
        "autoShutdownStatus": {
            "type": "String",
            "defaultValue": "Enabled"
        },
        "autoShutdownTime": {
            "type": "String",
            "defaultValue": "19:00"
        },
        "autoShutdownTimeZone": {
            "type": "String",
            "defaultValue": "UTC"
        },
        "autoShutdownNotificationStatus": {
            "type": "String",
            "defaultValue": "Enabled"
        },
        "autoShutdownNotificationLocale": {
            "type": "String",
            "defaultValue": "en"
        },
        "autoShutdownNotificationEmail": {
            "type": "String"
        }
    },
    "variables": {
        "nsgId": "[resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', parameters('networkSecurityGroupName'))]",
        "vnetId": "[resourceId(resourceGroup().name,'Microsoft.Network/virtualNetworks', parameters('virtualNetworkName'))]",
        "subnetRef": "[concat(variables('vnetId'), '/subnets/', parameters('subnetName'))]"
    },
    "resources": [
        {
            "type": "Microsoft.Network/networkInterfaces",
            "apiVersion": "2019-07-01",
            "name": "[parameters('networkInterfaceName')]",
            "location": "[parameters('location')]",
            "dependsOn": [
                "[concat('Microsoft.Network/networkSecurityGroups/', parameters('networkSecurityGroupName'))]",
                "[concat('Microsoft.Network/virtualNetworks/', parameters('virtualNetworkName'))]",
                "[concat('Microsoft.Network/publicIpAddresses/', parameters('publicIpAddressName'))]"
            ],
            "properties": {
                "ipConfigurations": [
                    {
                        "name": "ipconfig1",
                        "properties": {
                            "subnet": {
                                "id": "[variables('subnetRef')]"
                            },
                            "privateIPAllocationMethod": "Dynamic",
                            "publicIpAddress": {
                                "id": "[resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', parameters('publicIpAddressName'))]"
                            }
                        }
                    }
                ],
                "networkSecurityGroup": {
                    "id": "[variables('nsgId')]"
                }
            }
        },
        {
            "type": "Microsoft.Network/networkSecurityGroups",
            "apiVersion": "2019-02-01",
            "name": "[parameters('networkSecurityGroupName')]",
            "location": "[parameters('location')]",
            "properties": {
                "securityRules": [
                    {
                        "name": "default-allow-rdp",
                        "properties": {
                            "priority": 1000,
                            "protocol": "TCP",
                            "access": "Allow",
                            "direction": "Inbound",
                            "sourceApplicationSecurityGroups": [],
                            "destinationApplicationSecurityGroups": [],
                            "sourceAddressPrefix": "*",
                            "sourcePortRange": "*",
                            "destinationAddressPrefix": "*",
                            "destinationPortRange": "3389"
                        }
                    }
                ]
            }
        },
        {
            "type": "Microsoft.Network/virtualNetworks",
            "apiVersion": "2019-04-01",
            "name": "[parameters('virtualNetworkName')]",
            "location": "[parameters('location')]",
            "properties": {
                "addressSpace": {
                    "addressPrefixes": "[parameters('addressPrefixes')]"
                },
                "subnets": "[parameters('subnets')]"
            }
        },
        {
            "type": "Microsoft.Network/publicIpAddresses",
            "apiVersion": "2019-02-01",
            "name": "[parameters('publicIpAddressName')]",
            "location": "[parameters('location')]",
            "sku": {
                "name": "[parameters('publicIpAddressSku')]"
            },
            "properties": {
                "publicIpAllocationMethod": "[parameters('publicIpAddressType')]",
                "dnsSettings": {
                    "domainNameLabel": "[parameters('domainNameLabel')]"
                }
            }
        },
        {
            "type": "Microsoft.Compute/virtualMachines",
            "apiVersion": "2019-07-01",
            "name": "[parameters('virtualMachineName')]",
            "location": "[parameters('location')]",
            "dependsOn": [
                "[concat('Microsoft.Network/networkInterfaces/', parameters('networkInterfaceName'))]"
            ],
            "properties": {
                "hardwareProfile": {
                    "vmSize": "[parameters('virtualMachineSize')]"
                },
                "storageProfile": {
                    "osDisk": {
                        "createOption": "fromImage",
                        "managedDisk": {
                            "storageAccountType": "[parameters('osDiskType')]"
                        }
                    },
                    "imageReference": {
                        "publisher": "MicrosoftWindowsDesktop",
                        "offer": "Windows-10",
                        "sku": "19h1-pro",
                        "version": "latest"
                    }
                },
                "networkProfile": {
                    "networkInterfaces": [
                        {
                            "id": "[resourceId('Microsoft.Network/networkInterfaces', parameters('networkInterfaceName'))]"
                        }
                    ]
                },
                "osProfile": {
                    "computerName": "[parameters('virtualMachineName')]",
                    "adminUsername": "[parameters('adminUsername')]",
                    "adminPassword": "[parameters('adminPassword')]",
                    "windowsConfiguration": {
                        "enableAutomaticUpdates": true,
                        "provisionVmAgent": true
                    }
                },
                "licenseType": "Windows_Client"
            }
        },
        {
            "type": "Microsoft.DevTestLab/schedules",
            "apiVersion": "2017-04-26-preview",
            "name": "[concat('shutdown-computevm-', parameters('virtualMachineName'))]",
            "location": "[parameters('location')]",
            "dependsOn": [
                "[concat('Microsoft.Compute/virtualMachines/', parameters('virtualMachineName'))]"
            ],
            "properties": {
                "status": "[parameters('autoShutdownStatus')]",
                "taskType": "ComputeVmShutdownTask",
                "dailyRecurrence": {
                    "time": "[parameters('autoShutdownTime')]"
                },
                "timeZoneId": "[parameters('autoShutdownTimeZone')]",
                "targetResourceId": "[resourceId('Microsoft.Compute/virtualMachines', parameters('virtualMachineName'))]",
                "notificationSettings": {
                    "status": "[parameters('autoShutdownNotificationStatus')]",
                    "notificationLocale": "[parameters('autoShutdownNotificationLocale')]",
                    "timeInMinutes": "30",
                    "emailRecipient": "[parameters('autoShutdownNotificationEmail')]"
                }
            }
        }
    ],
    "outputs": {
        "adminUsername": {
            "type": "String",
            "value": "[parameters('adminUsername')]"
        },
        "FQDN": {
            "type": "String",
            "value": "[reference(concat('Microsoft.Network/publicIPAddresses/', parameters('publicIpAddressName')), '2016-03-30').dnsSettings.fqdn]"
        }
    }
}
DEPLOY

  parameters = {
    "storageAccountType" = "Standard_GRS"
  }

  deployment_mode = "Incremental"

  depends_on = [
    azurerm_virtual_machine.main
  ]
}
