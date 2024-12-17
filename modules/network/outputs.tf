output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "The ID of the virtual network."
}

output "subnet_id" {
  value       = azurerm_subnet.subnet.id
  description = "The ID of the subnet."
}

output "nsg_id" {
  value       = azurerm_network_security_group.nsg.id
  description = "The ID of the network security group."
}
