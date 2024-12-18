resource "azurerm_public_ip" "lb_ip" {
  name                = "${var.resources_name_prefix}lb-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = "${var.resources_name_prefix}lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.resources_name_prefix}lb-frontend-ip-conf"
    public_ip_address_id = azurerm_public_ip.lb_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_pool" {
  name            = "${var.resources_name_prefix}backend-pool"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "lb_probe" {
  name                = "${var.resources_name_prefix}health-probe"
  loadbalancer_id     = azurerm_lb.lb.id
  request_path        = var.health_check_path
  protocol            = "Http"
  port                = var.health_check_port
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "example" {
  name                           = "${var.resources_name_prefix}example-lb-rule"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = var.lb_frontend_port
  backend_port                   = var.lb_backend_port
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool.id]
  probe_id                       = azurerm_lb_probe.lb_probe.id
  idle_timeout_in_minutes        = 5
}
