variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region to deploy"
}

variable "temp_vm_subnet_id" {
  type        = string
  description = "ID of the subnet to deploy temporary VM"
}

variable "provision_script_path" {
  type        = string
  description = "Path to the provision script"
  default     = ""
}

variable "regenerate_image" {
  type        = bool
  default     = false
  description = "Should new image be created"
}

variable "resources_name_prefix" {
  type    = string
  default = "grid-image-"
}
