variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "temp_vm_subnet_id" {
  type = string
}

variable "provision_script_path" {
  type = string
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
