# creates a resource group
resource "azurerm_resource_group" "oe" {
    name     = "${var.resource_group_name}"
    location = "${var.location}"
}

# Random string for resources
resource "random_string" "id" {
  length = 8
  special = false
  lower = false
  upper = false
  number = true
}

# storage account which stores the vm template
resource "azurerm_storage_account" "oe" {
    name = "${var.prefix}sa${random_string.id.result}"
    resource_group_name = "${azurerm_resource_group.oe.name}"
    location            = "${azurerm_resource_group.oe.location}"
    account_kind             = "StorageV2"
    account_tier             = "Standard"
    account_replication_type = "LRS"
}

# storage container
resource "azurerm_storage_container" "oe" {
    name = "${var.prefix}sc${random_string.id.result}"
    resource_group_name = "${azurerm_resource_group.oe.name}"
    storage_account_name = "${azurerm_storage_account.oe.name}"
    container_access_type = "private"
}

# template
resource "azurerm_storage_blob" "oe" {
    name = "oe.vhd"

    resource_group_name = "${azurerm_resource_group.oe.name}"
    storage_account_name = "${azurerm_storage_account.oe.name}"
    storage_container_name = "${azurerm_storage_container.oe.name}"
    source_uri = "${var.source_vhd_path}"
    type = "page"

    lifecycle {
      # enable to prevent recreation
      prevent_destroy = "false"
    }
}

# creates virtual network
resource "azurerm_virtual_network" "oe" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.oe.location}"
  resource_group_name = "${azurerm_resource_group.oe.name}"
}

# creates internal subnet
resource "azurerm_subnet" "oe" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = "${azurerm_resource_group.oe.name}"
  virtual_network_name = "${azurerm_virtual_network.oe.name}"
  address_prefix       = "10.0.2.0/24"
}
# requests public ip
resource "azurerm_public_ip" "oe" {
  name                    = "${var.prefix}-pip"
  location                = "${azurerm_resource_group.oe.location}"
  resource_group_name     = "${azurerm_resource_group.oe.name}"
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30

  tags = {
    environment = "${var.tags}"
  }
}

# creates network security group
resource "azurerm_network_security_group" "oe" {
  name                        = "${var.prefix}-secgroup"
  location                    = "${azurerm_resource_group.oe.location}"
  resource_group_name         = "${azurerm_resource_group.oe.name}"
}

# creates network security group roles
resource "azurerm_network_security_rule" "oe_ssh" {
  name                        = "${var.prefix}-sec-role-ssh"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = "${var.source_address_prefixes}"
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = "${azurerm_resource_group.oe.name}"
  network_security_group_name = "${azurerm_network_security_group.oe.name}"
}
resource "azurerm_network_security_rule" "oe_http" {
  name                        = "${var.prefix}-sec-role-http"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefixes     = "${var.source_address_prefixes}"
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = "${azurerm_resource_group.oe.name}"
  network_security_group_name = "${azurerm_network_security_group.oe.name}"
}
resource "azurerm_network_security_rule" "oe_https" {
  name                        = "${var.prefix}-sec-role-https"
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefixes     = "${var.source_address_prefixes}"
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = "${azurerm_resource_group.oe.name}"
  network_security_group_name = "${azurerm_network_security_group.oe.name}"
}
resource "azurerm_network_security_rule" "oe_kafka" {
  name                        = "${var.prefix}-sec-role-kafka"
  priority                    = 104
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "29092"
  source_address_prefixes     = "${var.source_address_prefixes}"
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = "${azurerm_resource_group.oe.name}"
  network_security_group_name = "${azurerm_network_security_group.oe.name}"
}
resource "azurerm_network_security_rule" "oe_vnc" {
  name                        = "${var.prefix}-sec-role-vnc"
  priority                    = 105
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "5901"
  source_address_prefixes     = "${var.source_address_prefixes}"
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = "${azurerm_resource_group.oe.name}"
  network_security_group_name = "${azurerm_network_security_group.oe.name}"
}

resource "azurerm_network_security_rule" "oe_zookeeper" {
  name                        = "${var.prefix}-sec-role-zookeeper"
  priority                    = 106
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "22181"
  source_address_prefixes     = "${var.source_address_prefixes}"
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = "${azurerm_resource_group.oe.name}"
  network_security_group_name = "${azurerm_network_security_group.oe.name}"
}

resource "azurerm_network_security_rule" "oe_incoming" {
  name                        = "${var.prefix}-sec-role-oe-incoming"
  priority                    = 107
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = ["${azurerm_public_ip.oe.ip_address}"]
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = "${azurerm_resource_group.oe.name}"
  network_security_group_name = "${azurerm_network_security_group.oe.name}"

  depends_on = [ "azurerm_public_ip.oe"] 
}

resource "azurerm_network_security_rule" "oe_bots_zookeeper" {
  name                        = "${var.prefix}-sec-role-oe-bots-zookeeper"
  priority                    = 108
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "22181"
  source_address_prefixes     = "${var.source_address_prefixes_bots}"
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = "${azurerm_resource_group.oe.name}"
  network_security_group_name = "${azurerm_network_security_group.oe.name}"
}

resource "azurerm_network_security_rule" "oe_bots_kafka" {
  name                        = "${var.prefix}-sec-role-oe-bots-kafka"
  priority                    = 109
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "29092"
  source_address_prefixes     = "${var.source_address_prefixes_bots}"
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = "${azurerm_resource_group.oe.name}"
  network_security_group_name = "${azurerm_network_security_group.oe.name}"
}

# creates nic
resource "azurerm_network_interface" "oe" {
  name                      = "${var.prefix}-nic"
  location                  = "${azurerm_resource_group.oe.location}"
  resource_group_name       = "${azurerm_resource_group.oe.name}"
  network_security_group_id = "${azurerm_network_security_group.oe.id}"

  ip_configuration {
    name                          = "${var.prefix}-nic"
    subnet_id                     = "${azurerm_subnet.oe.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.oe.id}"
  }
}

# imports managed disk
resource "azurerm_managed_disk" "oe" {

  name                 = "${var.prefix}-osdisk"
  location             = "${azurerm_resource_group.oe.location}"
  resource_group_name  = "${azurerm_resource_group.oe.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Import"
  os_type              = "Linux"
  source_uri           = "${azurerm_storage_blob.oe.url}"
  disk_size_gb         = "120"

  depends_on = [ "azurerm_storage_blob.oe"] 
}

# creates virtual machine
resource "azurerm_virtual_machine" "oe" {
  name                  = "${var.prefix}-vm"
  location              = "${azurerm_resource_group.oe.location}"
  resource_group_name   = "${azurerm_resource_group.oe.name}"
  network_interface_ids = ["${azurerm_network_interface.oe.id}"]
  vm_size               = "${var.vm_size}"
  # deletes disks on destroy
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = "${var.prefix}-osdisk"
    os_type           = "Linux"
    managed_disk_id   = "${azurerm_managed_disk.oe.id}"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "Attach"
  }

  lifecycle {
    # enable to prevent recreation
    prevent_destroy = "false"
  }

  depends_on = [ "azurerm_managed_disk.oe"] 
}

# creates ad app
resource "random_string" "secret" {
  length = 32
  special = true
  lower = true
  upper = true
  number = true
}

resource "azuread_application" "oe" {
  name                       = "${var.prefix}-app"
  homepage                   = "https://${var.fqdn}"
  reply_urls                 = ["https://${var.fqdn}/teams/auth/silent-end"]
  type                       = "webapp/api"
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = true

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
    resource_access {
      id = "a154be20-db9c-4678-8ab7-66f6cc099a59"
      type = "Scope"
    }
    resource_access {
      id = "230c1aed-a721-4c5d-9cb4-a90514e508ef"
      type = "Role"
    }
    resource_access {
      id = "7b2449af-6ccd-4f4d-9f78-e550c193f0d1"
      type = "Role"
    }
    resource_access {
      id = "5b567255-7703-4780-807c-7be8301ae99b"
      type = "Role"
    }
    resource_access {
      id = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
      type = "Role"
    }
  }

  required_resource_access {
    resource_app_id = "c5393580-f805-4401-95e8-94b7a6ef2fc2"

    resource_access {
      id = "e2cea78f-e743-4d8f-a16a-75b629a038ae"
      type = "Role"
    }
  }
}

resource "azuread_application_password" "oe" {
  application_id        = "${azuread_application.oe.id}"
  value                = "${random_string.secret.result}"
  end_date             = "2999-01-01T01:01:01Z"

  depends_on = [ "random_string.secret"] 
}
