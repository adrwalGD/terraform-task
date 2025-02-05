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
  provision_script_path = "./scripts/initial.sh"
  temp_vm_subnet_id     = module.network_module.subnet_id
  regenerate_image      = var.regenerate_image
}

module "firewall" {
  source = "./modules/firewall"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = module.network_module.vnet_name
  load_balancer_ip = module.load_balancer.private_ip
  resources_subnet_ip = module.network_module.subnet_id
}

module "load_balancer" {
  source              = "./modules/load_balancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  lb_backend_port     = 80
  lb_frontend_port    = 80
  health_check_path   = "/"
  health_check_port   = 80
  subnet_id = module.network_module.subnet_id
}

module "vms_scale_set" {
  source                = "./modules/scale_set"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  public_key            = file("./ssh-keys")
  subnet_id             = module.network_module.subnet_id
  image_id              = module.vm_image.image_id
  nsg_id                = module.network_module.nsg_id
  lb_backend_pool_id    = module.load_balancer.backend_pool_id
  provision_script_path = "./scripts/landing-page.sh"
  instances_count       = 2
}
