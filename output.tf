# public ip
output "public_ip_address" {
  value = "${azurerm_public_ip.oe.ip_address}"
}

# app id
output "azuread_application_id" {
  value = "${azuread_application.oe.application_id}"
}

# app secret
output "azuread_application_password" {
  value = "${random_string.secret.result}"
}
