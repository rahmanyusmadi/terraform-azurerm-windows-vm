# Windows Azure Module
A Terraform module to create a Windows 10 Pro virtual machine in Azure.

## Example on how to use this module
```
module "mywindowsvm" {
  source   = "yusmadi/compute/azurerm"
  prefix   = "iamtesting"
  password = data.azurerm_key_vault_secret.main.value
}
```

## Reference

* [What is module?](https://www.terraform.io/docs/configuration/modules.html)
* [How can I improve this module?](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/proposing-changes-to-your-work-with-pull-requests)