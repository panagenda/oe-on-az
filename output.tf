# public ip
output "public_ip_address" {
  value = "${azurerm_public_ip.oe.ip_address}"
}
