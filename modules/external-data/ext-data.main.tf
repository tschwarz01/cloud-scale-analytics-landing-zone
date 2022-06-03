
resource "azurerm_storage_account" "stg" {
  for_each = local.storage_accounts

  name                            = "${var.global_settings.name_clean}${each.value.name}"
  resource_group_name             = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  location                        = var.global_settings.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  is_hns_enabled                  = false
  tags                            = try(var.tags, {})
}

resource "azurerm_storage_container" "container" {
  for_each = local.containers

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.stg[each.value.storage_key].name
}

module "private_endpoints" {
  source   = "../../services/networking/private_endpoint"
  for_each = local.private_endpoints

  location                   = try(each.value.location, var.global_settings.location, null)
  resource_group_name        = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  resource_id                = azurerm_storage_account.stg[each.value.storage_key].id
  name                       = "${var.global_settings.name_clean}${each.value.name}"
  private_service_connection = each.value.private_service_connection
  subnet_id                  = var.combined_objects_core.virtual_subnets[each.value.subnet_key].id
  private_dns                = each.value.private_dns
  private_dns_zones          = var.combined_objects_core.private_dns_zones
  tags                       = var.global_settings.tags
}


module "storage_diagnostics" {
  source   = "../../services/logmon/diagnostics"
  for_each = azurerm_storage_account.stg

  resource_id = each.value.id
  diagnostics = var.combined_objects_core.diagnostics
  profiles = {
    storage_account = {
      definition_key   = "storage_account"
      destination_type = "log_analytics"
      destination_key  = "central_logs"
    }
  }
}


module "blob_diagnostics" {
  source   = "../../services/logmon/diagnostics"
  for_each = azurerm_storage_account.stg

  resource_id = "${each.value.id}/blobServices/default"
  diagnostics = var.combined_objects_core.diagnostics
  profiles = {
    blob_services = {
      definition_key   = "blob_services"
      destination_type = "log_analytics"
      destination_key  = "central_logs"
    }
  }
}
