variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vm_admin_username" {
  type = string
}

variable "vm_admin_password" {
  type = string
}

variable "prefix" {
  type = string
}

variable "lb_backend_pool_id" {
  type = string
}

variable "lb_frontend_ip_config" {
  type = string
}

variable "lb_frontend_port" {
  type = number
}

variable "lb_backend_port" {
  type = number
}
