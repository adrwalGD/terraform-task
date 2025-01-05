output "firewall_public_ip" {
  value = azurerm_public_ip.fw_ip.ip_address
}
