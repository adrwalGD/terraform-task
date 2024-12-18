variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resources_name_prefix" {
  type    = string
  default = "grid-scale-set-"
}

variable "public_key" {
  type        = string
  description = "Public key/s to be used for VMs"
}

variable "username" {
  type        = string
  description = "Username for VMs"
  default     = "azureuser"
}

variable "provision_script_path" {
  type        = string
  description = "Path to the provision script"
  default     = ""
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet to deploy VMs"
}

variable "image_id" {
  type        = string
  description = "ID of the image to be used for VMs"
}

variable "nsg_id" {
  type        = string
  description = "ID of the network security group to be used for VMs"
}

variable "lb_backend_pool_id" {
  type        = string
  description = "ID of the backend pool of the load balancer"
}

variable "vms_sku" {
  type        = string
  description = "SKU of the VMs"
  default     = "Standard_B1s"
}

variable "instances_count" {
  type        = number
  description = "Number of VM instances"
  default     = 2
}

variable "disk_size_gb" {
  type        = number
  description = "Size of the OS disk in GB"
  default     = 30
}

variable "storage_account_type" {
  type        = string
  description = "Type of the storage account"
  default     = "Standard_LRS"
}
