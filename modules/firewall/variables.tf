variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region to deploy"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network"
}

variable "resources_subnet_ip" {
  type        = string
  description = "IP address with mask for the subnet"
}

variable "load_balancer_ip" {
    type        = string
    description = "IP address for the load balancer"
}
