data "azurerm_resource_group" "rg" {
  name = module.naming.resource_group.name
}

data "azurerm_resource_group" "net" {
  name = format("%s-%s", module.naming.resource_group.name, "net")
}

data "azurerm_subnet" "infra" {
  name                 = format("%s-%s", module.naming.subnet.name, "infrasubnet")
  virtual_network_name = module.naming.virtual_network.name
  resource_group_name  = local.rg_name
}

data "azurerm_virtual_network" "hub_vnet" {
  provider            = azurerm.connectivity
  name                = format("%s-hub-%s", "vnet", var.location)
  resource_group_name = format("%s-hub-%s", "rg", var.location)
}

data "azurerm_virtual_network" "spoke_vnet" {
  name                = module.naming.virtual_network.name
  resource_group_name = format("%s-%s", module.naming.resource_group.name, "net")
}