output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.lb_pool.id
}

output "lb_frontend_ip" {
  value = azurerm_public_ip.lb_ip.ip_address
}
