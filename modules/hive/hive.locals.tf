locals {
  keyvaults = {
    hive = {
      name                      = "hivemeta33"
      location                  = var.global_settings.location
      resource_group_key        = "hive_metastore"
      sku_name                  = "standard"
      enable_rbac_authorization = true
      soft_delete_enabled       = true
      purge_protection_enabled  = false

      diagnostic_profiles = {
        hivekv = {
          definition_key   = "azure_key_vault"
          destination_type = "log_analytics"
          destination_key  = "central_logs"
        }
      }
      private_endpoints = {
        vault = {
          name               = "hivemeta"
          resource_group_key = "hive_metastore"
          location           = var.global_settings.location
          vnet_key           = "vnet"
          subnet_key         = "private_endpoints"
          private_service_connection = {
            name                 = "hivemeta"
            is_manual_connection = false
            subresource_names    = ["vault"]
          }
          private_dns = {
            zone_group_name = "default"
            keys            = ["privatelink.vaultcore.azure.net"]
          }
        }
      }
    }
  }
  mssql_servers = {
    hive_sql = {
      name                          = "hive-meta"
      location                      = var.global_settings.location
      resource_group_key            = "hive_metastore"
      administrator_login           = "sqladmin"
      keyvault_key                  = "hive"
      public_network_access_enabled = false

      identity = {
        type = "SystemAssigned"
      }

      azuread_administrator = {
        login_username = "thosch@microsoft.com"
        object_id      = var.global_settings.client_config.object_id
        tenant_id      = var.global_settings.client_config.tenant_id
      }
    }
  }

  mssql_databases = {
    sqldb1 = {
      name               = "hive-meta"
      resource_group_key = "hive_metastore"
      mssql_server_key   = "hive_sql"
      license_type       = "LicenseIncluded"
      max_size_gb        = 4
      sku_name           = "BC_Gen5_2"
      diagnostic_profiles = {
        sqldb = {
          definition_key   = "azure_sql_database"
          destination_type = "log_analytics"
          destination_key  = "central_logs"
        }
      }
    }
  }

  private_endpoints = {
    sqls = {
      resource_id        = azurerm_mssql_server.sqls["hive_sql"].id
      name               = "sqls"
      resource_group_key = "hive_metastore"
      location           = var.global_settings.location
      vnet_key           = "vnet"
      subnet_key         = "private_endpoints"
      private_service_connection = {
        name                 = "sqls"
        is_manual_connection = false
        subresource_names    = ["sqlServer"]
      }
      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.database.windows.net"]
      }
    }
  }
}


