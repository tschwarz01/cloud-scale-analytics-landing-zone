
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = local.nsg_associations

  subnet_id                 = each.value.subnet_id
  network_security_group_id = each.value.nsg_id
}


resource "azurerm_databricks_workspace" "ws" {
  depends_on = [azurerm_subnet_network_security_group_association.nsg_assoc]
  for_each   = local.databricks_workspaces

  name                        = "${var.global_settings.name}-${each.value.name}"
  resource_group_name         = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  location                    = var.global_settings.location
  sku                         = lookup(each.value, "sku", "standard")
  managed_resource_group_name = lookup(each.value, "managed_resource_group_name", null)
  tags                        = var.tags

  public_network_access_enabled         = lookup(each.value, "public_network_access_enabled", null)
  network_security_group_rules_required = lookup(each.value, "network_security_group_rules_required", null)
  customer_managed_key_enabled          = lookup(each.value, "customer_managed_key_enabled", null)

  dynamic "custom_parameters" {
    for_each = lookup(each.value, "custom_parameters", null) == null ? [] : [1]

    content {
      no_public_ip             = lookup(each.value.custom_parameters, "no_public_ip", false)
      vnet_address_prefix      = lookup(each.value.custom_parameters, "vnet_address_prefix", null)
      nat_gateway_name         = lookup(each.value.custom_parameters, "nat_gateway_name", null)
      public_ip_name           = lookup(each.value.custom_parameters, "public_ip_name", null)
      storage_account_name     = lookup(each.value.custom_parameters, "storage_account_name", null)
      storage_account_sku_name = lookup(each.value.custom_parameters, "storage_account_sku_name", null)

      virtual_network_id  = can(each.value.custom_parameters.virtual_network_id) || can(each.value.custom_parameters.vnet_key) == false ? lookup(each.value.custom_parameters, "virtual_network_id", null) : var.combined_objects_core.virtual_networks[each.value.custom_parameters.vnet_key].id
      public_subnet_name  = can(each.value.custom_parameters.public_subnet_name) || can(each.value.custom_parameters.vnet_key) == false ? lookup(each.value.custom_parameters, "public_subnet_name", null) : var.combined_objects_core.virtual_subnets[each.value.custom_parameters.public_subnet_key].name
      private_subnet_name = can(each.value.custom_parameters.private_subnet_name) || can(each.value.custom_parameters.private_subnet_key) == false ? lookup(each.value.custom_parameters, "private_subnet_name", null) : var.combined_objects_core.virtual_subnets[each.value.custom_parameters.private_subnet_key].name

      public_subnet_network_security_group_association_id  = can(each.value.custom_parameters.public_subnet_network_security_group_association_id) || can(each.value.custom_parameters.public_subnet_key) == false ? lookup(each.value.custom_parameters, "public_subnet_network_security_group_association_id", null) : var.combined_objects_core.virtual_subnets[each.value.custom_parameters.public_subnet_key].id
      private_subnet_network_security_group_association_id = can(each.value.custom_parameters.private_subnet_network_security_group_association_id) || can(each.value.custom_parameters.public_subnet_key) == false ? lookup(each.value.custom_parameters, "private_subnet_network_security_group_association_id", null) : var.combined_objects_core.virtual_subnets[each.value.custom_parameters.private_subnet_key].id
    }
  }
}

