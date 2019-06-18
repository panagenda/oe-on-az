# vm id
output "vm_id" {
  value = "${azurerm_virtual_machine.oe.id}"
}

# public ip
output "public_ip_address" {
  value = "${azurerm_public_ip.oe.ip_address}"
}
