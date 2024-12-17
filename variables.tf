variable "regenerate_image" {
  type        = bool
  default     = false
  description = "Should new base image be created"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
  default     = "my-terraform-rg"
}

variable "location" {
  type        = string
  description = "Azure region to deploy"
  default     = "eastus"
}

variable "prefix" {
  type    = string
  default = "tf-demo"
}

variable "allowed_source_ips" {
  type        = list(string)
  description = "List of source IPs allowed to access LB"
  default     = ["your-public-ip"] # Replace with your public IP
}

variable "vm_admin_username" {
  type    = string
  default = "azureuser"
}

variable "vm_admin_password" {
  type      = string
  default   = "P@ssw0rd1234!"
  sensitive = true
}

variable "lb_frontend_port" {
  type    = number
  default = 80
}

variable "lb_backend_port" {
  type    = number
  default = 80
}
