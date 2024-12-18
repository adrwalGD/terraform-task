resource "azurerm_linux_virtual_machine_scale_set" "linux_vm_scale_set" {
  name                = "${var.resources_name_prefix}linux-vm-scale-set"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.vms_sku
  instances           = var.instances_count
  admin_username      = var.username
  admin_ssh_key {
    username   = var.username
    public_key = var.public_key
  }

  source_image_id = var.image_id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
    disk_size_gb         = var.disk_size_gb
  }

  network_interface {
    name                      = "${var.resources_name_prefix}nic"
    primary                   = true
    network_security_group_id = var.nsg_id
    ip_configuration {
      name                                   = "internal"
      subnet_id                              = var.subnet_id
      load_balancer_backend_address_pool_ids = [var.lb_backend_pool_id]
      primary                                = true
    }
  }

  extension {
    name                 = "${var.resources_name_prefix}landing-page-script"
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"
    settings             = <<SETTINGS
        {
            "script": "${base64encode(var.provision_script_path == "" ? "" : file(var.provision_script_path))}"
        }
    SETTINGS
  }
}
