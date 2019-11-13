# Windows Azure Module
A Terraform module to create a Windows virtual machine in Azure.

* By default create a single [Windows 10, version 1903 IT Pro](https://docs.microsoft.com/en-us/windows/whats-new/whats-new-windows-10-version-1903)
* Generate password and store secret in key vault
* Allow only one source IP address to access remotely

#### The simplest example how to use this module
```
module "windows" {
  source               = "yusmadi/windows/azurerm"
  my_public_ip_address = "13.15.17.19"
}
```

#### Full example how to use this module
```
module "windows" {
  source               = "yusmadi/windows/azurerm"
  prefix               = "mywindows"
  location             = "southeastasia"
  address_space        = ["10.0.0.0/16"]
  address_prefix       = "10.0.2.0/24"
  my_public_ip_address = "13.15.17.19"
  vm_size              = "Standard_DS1_v2"
  publisher            = "MicrosoftWindowsDesktop"
  offer                = "Windows-10"
  sku                  = "19h1-pro"
  image_version        = "latest"
}
```

#### Reference

* [What is module?](https://www.terraform.io/docs/configuration/modules.html)
* [How can I improve this module?](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/proposing-changes-to-your-work-with-pull-requests)
* [How is this module versioned?](https://semver.org/)
* [What are the available size of virtual machines?](https://azure.microsoft.com/en-us/documentation/articles/virtual-machines-size-specs/)
