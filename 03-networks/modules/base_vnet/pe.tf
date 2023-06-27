resource "azurerm_private_endpoint" "acr" {
  count               = contains(var.private_dns_zones, "privatelink.azurecr.io") && var.env != "hub" ? 1 : 0
  name                = format("%s-%s", module.naming.private_endpoint.name, "acr")
  location            = var.location
  resource_group_name = local.rg_name
  subnet_id           = azurerm_subnet.snet["pesubnet"].id

  private_service_connection {
    name                           = format("%s-%s", module.naming.private_service_connection.name, "acr")
    is_manual_connection           = false
    private_connection_resource_id = data.azurerm_container_registry.acr[count.index].id
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = format("%s-%s", module.naming.private_dns_zone_group.name, "acr")
    private_dns_zone_ids = [azurerm_private_dns_zone.dns["privatelink.azurecr.io"].id]
  }
}