output "fqdn" {
    value       = azurerm_public_ip.main.fqdn
    description = "Hostname of the Windows virtual machine"
}

output "username" {
    value       = azurerm_virtual_machine.main.os_profile[0].admin_username
    description = "Username to access the Windows virtual machine"
}