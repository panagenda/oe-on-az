# public ip
output "public_ip_address" {
  value = "${azurerm_public_ip.oe[0].ip_address}"
}
# private ip
output "private_ip_address" {
  value = "${azurerm_network_interface.oe[0].ip_configuration[0].private_ip_address}"
}
