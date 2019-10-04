# panagenda OfficeExpert on Azure

This repository contains everything needed to deploy panagenda OfficeExpert on Azure.

## TL;DR

1. Access [shell.azure.com](https://shell.azure.com/) and start a Bash
2. Clone this repository by executing `git clone https://gitlab.com/nmeisenzahl/oe-on-az.git; cd oe-on-az`
3. Export your tenant id by executing `export tenantId="xxxxxxxx-xxxx-xxxx-xxx-xxxxxxxxxxxx"`
4. Export your subscriptions id by executing `export subscriptionId="xxxxxxxx-xxxx-xxxx-xxx-xxxxxxxxxxxx"`
5. Export the template URL we provided you with `export template="https://xxxx.blob.core.windows.net/xxxx/xxxx.vhd"`
6. Execute `./prep.sh` to prepare everything for Terraform
7. Customize the `vars.tf` based on your needs (you can either use the [Azure Cloud Shell editor](https://docs.microsoft.com/en-us/azure/cloud-shell/using-cloud-shell-editor) or `vi vars.tf`)
9. Execute `./up.sh` to deploy OfficeExpert
10. Review our [Setup Guide](https://img.panagenda.com/download/OfficeExpert/OfficeExpert_SetupGuide_EN.pdf) for further installation steps) or run the automated configuration (more details below)

## Deployment details

The above steps steps deploying the following Azure resources.

### prep.sh

OfficeExpert itself will be deployed using Terraform. This script will deploy everything needed to run Terraform.

- Resource Group (pana-oe-tf-rg)
- Storage Account which is used to store the Terraform statefile in a Blob Storage Container
- Vault to store all IDs and secrets for later use
- A Service Principal Terraform runs with

### up.sh

This will run the Terraform project to deploy everything related to OfficeExpert. Depening on your configuration (var.tf) the Appliance will be deployed either into an existing Azure virtual network or will create a new one including a public IP.

- Storage Account to store Virtual Machine template in a Blob Storage Account
- Virtual Machine
- Disk
- Virtual Network Interface
- Network Interface (public IP only)
- Network Security Group (public IP only)

### config.sh

The config script will finalize the Appliance configuration. This step is only supported with the public IP deployment option. Review our [Setup Guide](https://img.panagenda.com/download/OfficeExpert/OfficeExpert_SetupGuide_EN.pdf) for further information on how to configure the Appliance manually. 

- Sets Hostname and timezone
- Configures and starts Office Experts
- Sets a new root password

Execute `./config.sh "my-oe.my-domain.com" "Europe/Berlin" "my-oe-secret" "my-root-password"`

Make sure sure your Appliance is reachable via SSH and the provided hostname before!

## Requirements

If you want to use your local environment instead of the Azure Cloud Shell you will need to fulfil the following requirements:
- Linux shell or Azure Cloud Shell
- Azure CLI - download [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- Terraform CLI - download [here](https://www.terraform.io/downloads.html)

We tested the deployment with following version:
- Azure CLI 2.0.66 and above
- Terraform v0.12 and above

## Customize the deployment

You can customize your deployment by editing the `vars.tf` file. 

| Variables                    | Default value   | Details                             |
| :--------------------------- | :-------------- | :---------------------------------- | 
| prefix                       | oe              | Prefix used for different resources |
| resource_group_name          | oe-appliance    | Resource Group name                 |
| vm_size                      | Standard_B2ms   | VM size                             |
| data_disk                    | 100             | size of the data disk (GB)          |
| location                     | West Europe     | Resource Location                   |
| source_address_prefixes      | -               | External IPs allowed to access OE   |
| source_address_prefixes_bots | -               | Bots IPs allowed to access OE       |
| rg                           | -               | Resource Group of an existing VNet  |
| vnet                         | -               | Name of an existing VNet            |
| subnet                       | -               | Subnet name of an existing VNet     |
| ip                           | -               | IP of an existing VNet              |

Everything related to the Azure Vault and Storage Account for Terraform can be customized in `prep.sh`.

## Destroy the deployment

1. Export your tenant id by executing `export tenantId="xxxxxxxx-xxxx-xxxx-xxx-xxxxxxxxxxxx"`
2. Export your subscriptions id by executing `export subscriptionId="xxxxxxxx-xxxx-xxxx-xxx-xxxxxxxxxxxx"`
3. Run `destroy.sh` to destroy your deployment. This will destroy all created resources!
