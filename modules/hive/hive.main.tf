resource "random_password" "sql_admin" {
  count = try(local.mssql_servers["hive_sql"].administrator_login_password, null) == null ? 1 : 0

  length           = 128
  special          = true
  upper            = true
  numeric          = true
  override_special = "$#%"
}


resource "azurerm_key_vault_secret" "sql_admin_password" {
  count = try(local.mssql_servers["hive_sql"].administrator_login_password, null) == null ? 1 : 0

  name         = "hive-sql-admin-password"
  value        = random_password.sql_admin.0.result
  key_vault_id = module.keyvault["hive"].id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}


module "keyvault" {
  source   = "../../services/general/keyvault/keyvault"
  for_each = local.keyvaults

  global_settings       = var.global_settings
  settings              = each.value
  location              = var.global_settings.location
  resource_group_name   = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  name                  = "${var.global_settings.name}-${each.value.name}"
  tags                  = var.tags
  combined_objects_core = var.combined_objects_core
}


resource "azurerm_mssql_server" "sqls" {
  for_each = local.mssql_servers
  name     = "${var.global_settings.name}-${each.value.name}"

  resource_group_name          = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  location                     = var.global_settings.location
  version                      = "12.0"
  administrator_login          = each.value.administrator_login
  administrator_login_password = try(each.value.administrator_login_password, azurerm_key_vault_secret.sql_admin_password.0.value)
  minimum_tls_version          = "1.2"

  azuread_administrator {
    login_username = each.value.azuread_administrator.login_username
    object_id      = each.value.azuread_administrator.object_id
    tenant_id      = each.value.azuread_administrator.tenant_id
  }

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_mssql_database" "mssqldb" {
  for_each = local.mssql_databases

  name         = "${var.global_settings.name}-${each.value.name}"
  server_id    = azurerm_mssql_server.sqls[each.value.mssql_server_key].id
  license_type = try(each.value.license_type, null)
  max_size_gb  = try(each.value.max_size_gb, null)
  sku_name     = try(each.value.sku_name, null)
  tags         = try(var.tags, {})
}


module "private_endpoints" {
  source   = "../../services/networking/private_endpoint"
  for_each = local.private_endpoints

  location                   = try(each.value.location, var.global_settings.location, null)
  resource_group_name        = try(each.value.resource_group_name, var.combined_objects_core.resource_groups[try(each.value.resource_group.key, each.value.resource_group_key)].name)
  resource_id                = each.value.resource_id
  name                       = "${var.global_settings.name_clean}${each.value.name}"
  private_service_connection = each.value.private_service_connection
  subnet_id                  = try(each.value.subnet_id, var.combined_objects_core.virtual_subnets[each.value.subnet_key].id)
  private_dns                = each.value.private_dns
  private_dns_zones          = var.combined_objects_core.private_dns_zones
  tags                       = try(var.tags, {})
}


module "diagnostics" {
  source   = "../../services/logmon/diagnostics"
  for_each = azurerm_mssql_database.mssqldb

  resource_id = each.value.id
  diagnostics = var.combined_objects_core.diagnostics
  profiles    = local.mssql_databases[each.key].diagnostic_profiles
}
