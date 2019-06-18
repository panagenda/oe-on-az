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
    account_kind             = "Storage"
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

  depends_on = [ "azurerm_managed_disk.oe"] 
}
