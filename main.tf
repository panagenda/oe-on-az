provider "azurerm" {
    version = "~>1.30.1"
}

provider "random" {
    version = "~> 2.1"
}

terraform {
    backend "azurerm" {
        key = "oe.terraform.tfstate"
    }
}
