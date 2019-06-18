# panagenda OfficeExpert on Azure

This repository contains everything needed to deploy panagenda OfficeExpert in Azure.

## TL;DR

- Access (https://shell.azure.com/ "shell.azure.com") and start a Bash
- Clone this repository by executing `git clone https://xxx/oe-on-az; cd oe-on-az`
- Export your tenent id by executing `export tenentId="xxxxxxxx-xxxx-xxxx-xxx-xxxxxxxxxxxx`
- Export your subscriptions id by executing `export subscriptionId="xxxxxxxx-xxxx-xxxx-xxx-xxxxxxxxxxxx`
- Execute `prep.sh` to prepare everything for Terraform
- Execute `up.sh` to deploy OfficeExpert
- Review our (https://img.panagenda.com/download/OfficeExpert/OfficeExpert_SetupGuide_EN.pdf "Setup Guide") for further installation steps

## Requirements

If you want to use your local environment instead of the Azure Cloud Shell you will to fulfil the following requirements:
- Linux shell
- Azure CLI - download (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest "here")
- Terraform CLI - download (https://www.terraform.io/downloads.html "here")

We tested the deployment with following version:
Azure CLI: 2.0.66 and above
Terraform CLI: v0.12.0 and above

## Customize the deployment

You can customize your deployment by editing the `var.tf` file. Everything related to the Azure Vault and Storage-Account for Terraform can be customized in `prep.sh`. Change the `template` variable within the `up.sh` script to install a different version.

| Variables               | Default value   | Default value                       |
| ----------------------- |:---------------:| -------------------------------- --:| 
| prefix                  | oe              | Prefix used for different resources |
| resource_group_name     | oe-appliance    | Resource Group name                 |
| vm_size                 | Standard_B2ms   | VM size                             |
| location                | West Europe     | Resource Location                   |
| source_address_prefixes | -               | External IPs allowed to access OE   |
| tags                    | production      | tag name                            |

## Destroy the deployment

Run `destroy.sh` to destroy your deployment. This will destroy all created resources!
