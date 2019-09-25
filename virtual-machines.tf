# creates virtual machine - static private ip
resource "azurerm_virtual_machine" "oe" {
  name                  = "${var.prefix}-vm"
  count                 = "${var.subnet == "" ? 0 : 1}"
  location              = "${azurerm_resource_group.oe.location}"
  resource_group_name   = "${azurerm_resource_group.oe.name}"
  network_interface_ids = ["${azurerm_network_interface.oe[0].id}"]
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

# creates virtual machine - static puplic ip (custom network deployment)
resource "azurerm_virtual_machine" "oe-custom-public" {
  name                  = "${var.prefix}-vm"
  count                 = "${var.subnet == "" ? 1 : 0}"
  location              = "${azurerm_resource_group.oe.location}"
  resource_group_name   = "${azurerm_resource_group.oe.name}"
  network_interface_ids = ["${azurerm_network_interface.oe-custom-public[0].id}"]
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