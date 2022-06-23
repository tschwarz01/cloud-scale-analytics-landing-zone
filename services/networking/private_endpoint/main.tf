resource "azurerm_private_endpoint" "pep" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags                = var.tags


  private_service_connection {
    name                           = var.private_service_connection.name
    private_connection_resource_id = var.resource_id
    is_manual_connection           = lookup(var.private_service_connection, "is_manual_connection", false)
    subresource_names              = var.private_service_connection.subresource_names
    request_message                = can(var.private_service_connection.request_message) ? var.private_service_connection.request_message : null
  }

  private_dns_zone_group {
    name = lookup(var.private_dns, "zone_group_name", "default")

    private_dns_zone_ids = concat(
      flatten([
        for key in var.private_dns.keys : [
          var.private_dns_zones[key]
        ]
        ]
      )
    )

  }
}
