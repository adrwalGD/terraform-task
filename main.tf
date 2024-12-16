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

# -------------------------------- Network Module --------------------------------
#vnet
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

#subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

#nsg
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

#nsg ssh rule
resource "azurerm_network_security_rule" "ssh" {
  name                        = "ssh"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

#nsg http rule
resource "azurerm_network_security_rule" "http" {
  name                        = "http"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

#public ip
resource "azurerm_public_ip" "public_ip" {
  name                = "public_ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

# -------------------------------- Network Module --------------------------------

resource "azurerm_network_interface" "temp_nic" {
  name                = "main-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

#temp vm for image
# resource "azurerm_linux_virtual_machine" "temp_vm" {
#   name                            = "temp-vm"
#   resource_group_name             = azurerm_resource_group.rg.name
#   location                        = azurerm_resource_group.rg.location
#   size                            = "Standard_B1s"
#   admin_username                  = "azureuser"
#   admin_password                  = "P@ssw0rd1234!"
#   disable_password_authentication = false
#   network_interface_ids           = [azurerm_network_interface.temp_nic.id]
#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-focal"
#     sku       = "20_04-lts"
#     version   = "latest"
#   }
# }

# Base VM
resource "azurerm_virtual_machine" "base_temp_vm" {
  name                  = "base-temp-vm"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  vm_size               = "Standard_B1s"
  network_interface_ids = [azurerm_network_interface.temp_nic.id]

  storage_os_disk {
    os_type           = "Linux"
    name              = "base-temp-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_profile {
    computer_name  = "tempvm"
    admin_username = "azureuser"
    admin_password = "P@ssw0rd1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Create snapshot of temp vm disk
resource "azurerm_snapshot" "os_image_snap" {
  name                = "os-image-copy-tf"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  create_option       = "Copy"
  source_uri          = azurerm_virtual_machine.base_temp_vm.storage_os_disk[0].managed_disk_id
  depends_on          = [azurerm_virtual_machine.base_temp_vm]
}

resource "azurerm_managed_disk" "disk_from_snap" {
  name                 = "disk-from-snap"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Copy"
  source_resource_id   = azurerm_snapshot.os_image_snap.id
  depends_on           = [azurerm_snapshot.os_image_snap]
  hyper_v_generation   = "V1"
  os_type              = "Linux"
}

# 2nd nic
resource "azurerm_network_interface" "nic2" {
  name                = "main-nic2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_virtual_machine" "vm_from_snapshot" {
  name                  = "vm-from-disk-from-snap"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  vm_size               = "Standard_B1s"
  network_interface_ids = [azurerm_network_interface.nic2.id]

  storage_os_disk {
    os_type = "Linux"
    # name    = "os-disk-snaps"
    name              = azurerm_managed_disk.disk_from_snap.name
    caching       = "ReadWrite"
    create_option = "Attach"
    managed_disk_id   = azurerm_managed_disk.disk_from_snap.id
    # image_uri = azurerm_virtual_machine.base_temp_vm.storage_os_disk[0].managed_disk_id
  }
  depends_on = [ azurerm_managed_disk.disk_from_snap ]
  # depends_on = [azurerm_virtual_machine.base_temp_vm]
}

# resource "azurerm_virtual_machine_extension" "vmscript" {
#     name                 = "vmscript"
#     virtual_machine_id   = azurerm_linux_virtual_machine.temp_vm.id
#     publisher            = "Microsoft.Azure.Extensions"
#     type                 = "CustomScript"
#     type_handler_version = "2.0"
#     protected_settings = <<SETTINGS
#         {
#             "script": "${base64encode(file("./script.sh"))}"
#         }
# SETTINGS

#     depends_on = [ azurerm_linux_virtual_machine.temp_vm]
# }

# resource "azurerm_image" "my_image" {
#   name                      = "my-image"
#   resource_group_name       = azurerm_resource_group.rg.name
#   location                  = azurerm_resource_group.rg.location
#   source_virtual_machine_id = azurerm_linux_virtual_machine.temp_vm.id
#   depends_on                = [azurerm_linux_virtual_machine.temp_vm]
# }

# resource "azurerm_linux_virtual_machine" "vm_from_vm_image" {
#   name                            = "vm-from-vm-image"
#   resource_group_name             = azurerm_resource_group.rg.name
#   location                        = azurerm_resource_group.rg.location
#   size                            = "Standard_B1s"
#   admin_username                  = "azureuser"
#   admin_password                  = "P@ssw0rd1234!"
#   disable_password_authentication = false
#   network_interface_ids           = [azurerm_network_interface.temp_nic.id]
#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_id = azurerm_image.my_image.id
#   depends_on      = [azurerm_image.my_image]
# }


# #-----------------------------------------------------------
# # Resource Group
# #-----------------------------------------------------------
# resource "azurerm_resource_group" "rg" {
#   name     = var.resource_group_name
#   location = var.location
# }

# #-----------------------------------------------------------
# # Call Network Module
# #-----------------------------------------------------------
# module "network" {
#   source                  = "./modules/network"
#   resource_group_name     = azurerm_resource_group.rg.name
#   location                = azurerm_resource_group.rg.location
#   allowed_source_ips      = var.allowed_source_ips
#   lb_frontend_port        = var.lb_frontend_port
#   lb_backend_port         = var.lb_backend_port
#   vmss_subnet_cidr        = "10.0.2.0/24"
# }

# #-----------------------------------------------------------
# # Temporary VM for Image Creation
# #-----------------------------------------------------------
# module "compute" {
#   source                = "./modules/compute"
#   resource_group_name   = azurerm_resource_group.rg.name
#   location              = azurerm_resource_group.rg.location
#   vm_admin_username     = var.vm_admin_username
#   vm_admin_password     = var.vm_admin_password
#   vnet_name             = module.network.vnet_name
#   subnet_id             = module.network.vmss_subnet_id
#   prefix                = var.prefix
#   lb_backend_pool_id    = module.network.lb_backend_pool_id
#   lb_frontend_ip_config = module.network.lb_frontend_ip_config
#   lb_frontend_port      = var.lb_frontend_port
#   lb_backend_port       = var.lb_backend_port
# }

# # Output for testing
# output "load_balancer_public_ip" {
#   value = module.network.lb_public_ip_address
# }