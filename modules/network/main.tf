resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "vmss" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.vmss_subnet_cidr]
}

resource "azurerm_public_ip" "lb_public_ip" {
  name                = "${var.prefix}-lb-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-lb"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "bepool" {
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "BackendPool"
}

resource "azurerm_lb_probe" "http_probe" {
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "httpProbe"
  protocol            = "Http"
  port                = var.lb_backend_port
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "lb_rule" {
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "httpRule"
  protocol                       = "Tcp"
  frontend_port                  = var.lb_frontend_port
  backend_port                   = var.lb_backend_port
  frontend_ip_configuration_name = azurerm_lb.frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bepool.id
  probe_id                       = azurerm_lb_probe.http_probe.id
}

# Network Security Group to allow only certain IPs and ports
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_network_security_rule" "allow_lb_inbound" {
  name                        = "Allow-HTTP-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = [var.lb_frontend_port]
  source_address_prefixes     = var.allowed_source_ips
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.vmss.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "vmss_subnet_id" {
  value = azurerm_subnet.vmss.id
}

output "lb_backend_pool_id" {
  value = azurerm_lb_backend_address_pool.bepool.id
}

output "lb_frontend_ip_config" {
  value = azurerm_lb.frontend_ip_configuration[0].name
}

output "lb_public_ip_address" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}
