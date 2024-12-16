variable "resource_group_name" {
  type    = string
  default = "grid-terraform"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "allowed_source_ips" {
  type = list(string)
}

variable "lb_frontend_port" {
  type = number
}

variable "lb_backend_port" {
  type = number
}

variable "vmss_subnet_cidr" {
  type = string
}

variable "prefix" {
  type    = string
  default = "gd-tf"
}
