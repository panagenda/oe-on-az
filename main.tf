provider "azurerm" {
    version = "~>2.0.0"
    features {
    }
    environment = "public"
}

provider "random" {
    version = "~> 2.1"
}

terraform {
    backend "azurerm" {
        key = "oe.terraform.tfstate"
        environment = "public"
    }
}
