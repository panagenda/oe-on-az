# Resource Group
variable resource_group_name {
    default = "oe-rg"
}

# virutal machine size
variable vm_size {
    default = "Standard_B2ms"
}

# managed disk path
variable "source_vhd_path" {
    default = ""
}

# prefix
variable prefix {
    default = "oe"
}

# Location
variable location {
    default = "West Europe"
}

# Source IP addresses
variable source_address_prefixes {
    type    = "list"
    default = ["127.0.0.1"]
}

# Tags
variable tags {
    default = "production"
}
