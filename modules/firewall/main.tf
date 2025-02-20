# Firewall Public IP
resource "azurerm_public_ip" "fw_ip" {
  name                = "example-fw-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Firewall management Public IP
resource "azurerm_public_ip" "fw_mgmt_ip" {
  name                = "example-fw-mgmt-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# AzureFirewallSubnet
resource "azurerm_subnet" "subnet_fw" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.1.0/26"]
}

# AzureFirewallManagementSubnet
resource "azurerm_subnet" "subnet_fw_mgmt" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.1.64/26"]
}

# Firewall
resource "azurerm_firewall" "firewall" {
  name                = "example-firewall"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  management_ip_configuration {
    name                 = "example-mgmt-ip-config"
    subnet_id            = azurerm_subnet.subnet_fw_mgmt.id
    public_ip_address_id = azurerm_public_ip.fw_mgmt_ip.id
  }

  ip_configuration {
    name                 = "example-ip-config"
    subnet_id            = azurerm_subnet.subnet_fw.id
    public_ip_address_id = azurerm_public_ip.fw_ip.id
  }
}

# Firewall Rule
resource "azurerm_firewall_policy" "firewall_policy" {
  name                = "example-fw-policy"
  location            = var.location
  resource_group_name = var.resource_group_name
}


resource "azurerm_firewall_nat_rule_collection" "example" {
  name                = "testcollection"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Dnat"

  rule {
    name                  = "testrule"
    source_addresses      = ["*"]
    destination_ports     = ["80"]
    destination_addresses = [azurerm_public_ip.fw_ip.ip_address]
    translated_port       = 80
    translated_address    = var.load_balancer_ip
    protocols             = ["TCP"]
  }
}

# Route Table for Firewall
resource "azurerm_route_table" "fw_rt" {
  name                = "example-rt"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_route" "route_to_firewall" {
  name                   = "route-through-firewall"
  route_table_name       = azurerm_route_table.fw_rt.name
  resource_group_name    = var.resource_group_name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}
