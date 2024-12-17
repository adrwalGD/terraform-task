terraform {
  required_version = ">=1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "c539c22d-81df-4900-93d0-f5d20ccc64b9"
}

resource "azurerm_resource_group" "rg" {
  name     = "grid-terraform"
  location = "westeurope"
}

module "network_module" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  nsg_rules = [{
    name                       = "ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    },
    {
      name                       = "http"
      priority                   = 1002
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
  }]
}

module "vm_image" {
  source                = "./modules/vm_image"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  provision_script_path = "./script.sh"
  temp_vm_subnet_id = module.network_module.subnet_id
}

#vms from image
resource "azurerm_linux_virtual_machine_scale_set" "linux_vm_scale_set" {
  name                = "linux-vm-scale-set"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_B1s"
  instances           = 2
  admin_username      = "azureuser"
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("./ssh-keys")
  }

  source_image_id = module.vm_image.image_id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name                      = "nic"
    primary                   = true
    network_security_group_id = module.network_module.nsg_id
    ip_configuration {
      name                                   = "internal"
      subnet_id                              = module.network_module.subnet_id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_pool.id]
    }
  }

  extension {
    name                 = "landing-page-script"
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"
    settings             = <<SETTINGS
        {
            "script": "${base64encode(file("./landing-page.sh"))}"
        }
    SETTINGS
  }

}

# Load Balancer public IP
resource "azurerm_public_ip" "lb_ip" {
  name                = "lb_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# load balancaer
resource "azurerm_lb" "lb" {
  name                = "lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "lb-frontend-ip-conf"
    public_ip_address_id = azurerm_public_ip.lb_ip.id
  }
}

# Define Backend Pool
resource "azurerm_lb_backend_address_pool" "lb_pool" {
  name            = "backend-pool"
  loadbalancer_id = azurerm_lb.lb.id
}

# Health Probe for Port 80
resource "azurerm_lb_probe" "lb_probe" {
  name                = "health-probe"
  loadbalancer_id     = azurerm_lb.lb.id
  request_path        = "/"
  protocol            = "Http"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Load Balancer Rule for Port 80
resource "azurerm_lb_rule" "example" {
  name                           = "example-lb-rule"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.lb.frontend_ip_configuration[0].name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_pool.id]
  probe_id                       = azurerm_lb_probe.lb_probe.id
  idle_timeout_in_minutes        = 5
}
