variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resources_name_prefix" {
  type    = string
  default = "grid-lb-"
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "health_check_port" {
  type    = number
  default = 80
}

variable "lb_frontend_port" {
  type    = number
  default = 80
}

variable "lb_backend_port" {
  type    = number
  default = 80
}

variable "subnet_id" {
  type = string
}
