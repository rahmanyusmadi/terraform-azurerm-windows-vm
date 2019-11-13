output "fqdn" {
    value       = azurerm_public_ip.main.fqdn
    description = "Hostname of the Windows virtual machine"
}

output "username" {
    value       = "${var.prefix}-user"
    description = "Username to access the Windows virtual machine"
}

output "password" {
    value       = random_password.password.result
    description = "Username to access the Windows virtual machine"
    sensitive   = true
}
