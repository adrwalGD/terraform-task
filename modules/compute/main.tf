# Temporary VM for image preparation
resource "azurerm_virtual_machine" "temp_vm" {
  name                  = "${var.prefix}-temp-vm"
  resource_group_name   = var.resource_group_name
  location              = var.location
  network_interface_ids = [azurerm_network_interface.temp_nic.id]
  vm_size               = "Standard_B1s"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = "${var.prefix}-temp-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "tempvm"
    admin_username = var.vm_admin_username
    admin_password = var.vm_admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  # Custom script to install Apache and set up a simple website
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install apache2 -y",
      "sudo sh -c 'echo \"<html><h1>Server: $(hostname)</h1></html>\" > /var/www/html/index.html'",
      "sudo systemctl enable apache2",
      "sudo systemctl start apache2"
    ]
    connection {
      type     = "ssh"
      user     = var.vm_admin_username
      password = var.vm_admin_password
      host     = azurerm_network_interface.temp_nic.private_ip_address
    }
  }

  depends_on = [azurerm_network_interface.temp_nic]
}

resource "azurerm_network_interface" "temp_nic" {
  name                = "${var.prefix}-temp-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create a Managed Image from the temporary VM's OS disk
data "azurerm_virtual_machine" "temp_vm_data" {
  name                = azurerm_virtual_machine.temp_vm.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_image" "custom_image" {
  name                = "${var.prefix}-custom-image"
  resource_group_name = var.resource_group_name
  location            = var.location

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = data.azurerm_virtual_machine.temp_vm_data.storage_os_disk[0].managed_disk_id
  }

  depends_on = [azurerm_virtual_machine.temp_vm]
}

# After image creation, we could optionally remove the temporary VM
# But here we keep it simple and do not automatically remove the temporary VM
# If desired, you can delete the temp VM after manually running `az vm deallocate and generalize`
# or use a null_resource and local-exec to run azure CLI commands to generalize the VM before creating image.

# Create VM Scale Set from the custom image
resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "${var.prefix}-vmss"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard_B1s"
  instances           = 3
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  source_image_id     = azurerm_image.custom_image.id
  upgrade_mode        = "Manual"

  network_interface {
    name    = "primary"
    primary = true
    ip_configuration {
      name                                   = "internal"
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = [var.lb_backend_pool_id]
    }
  }

  # Custom script extension to ensure each VM has Apache and hostname page (if image isn't pre-made)
  # If image already has Apache, this is optional or can be used to update content.
  extension {
    name                 = "hostname-script"
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"
    settings             = <<-SETTINGS
      {
        "commandToExecute": "bash -c 'echo \"<html><h1>Server: $(hostname)</h1></html>\" > /var/www/html/index.html && systemctl restart apache2'"
      }
    SETTINGS
  }

  depends_on = [azurerm_image.custom_image]
}
