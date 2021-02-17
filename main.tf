provider "azurerm" {
    features {
    }
    environment = "public"
}

provider "random" {
}

terraform {
    backend "azurerm" {
        key = "oe.terraform.tfstate"
        environment = "public"
    }
}
