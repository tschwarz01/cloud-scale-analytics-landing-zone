locals {

  keyvaults = {
    ingestion = {
      name                      = "ingestion"
      location                  = var.global_settings.location
      resource_group_key        = "ingestion_framework"
      sku_name                  = "standard"
      enable_rbac_authorization = true
      soft_delete_enabled       = true
      purge_protection_enabled  = false

      diagnostic_profiles = {
        databricks-mon = {
          definition_key   = "azure_key_vault"
          destination_type = "log_analytics"
          destination_key  = "central_logs"
        }
      }

      private_endpoints = {
        vault = {
          name               = "kvingestion"
          resource_group_key = "ingestion_framework"
          location           = var.global_settings.location
          vnet_key           = "vnet"
          subnet_key         = "private_endpoints"

          private_service_connection = {
            name                 = "kvingestion"
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
    ingestion_sqls = {
      name                          = "adf-metastore"
      location                      = var.global_settings.location
      resource_group_key            = "ingestion_framework"
      administrator_login           = "sqladmin"
      keyvault_key                  = "ingestion"
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
    ingestion_sqldb = {
      name               = "adf-metastore-sqldb"
      resource_group_key = "ingestion_framework"
      mssql_server_key   = "ingestion_sqls"
      license_type       = "LicenseIncluded"
      max_size_gb        = 4
      sku_name           = "BC_Gen5_2"

      diagnostic_profiles = {
        sqldb = {
          definition_key   = "azure_sql_database"
          destination_type = "log_analytics"
          destination_key  = "central_logs" # Needs to be deployed in launchpad first
        }
      }
    }
  }

  private_endpoints = {
    ingestion_sqls = {
      resource_id        = azurerm_mssql_server.sqls["ingestion_sqls"].id
      name               = "ingestion_sqls"
      resource_group_key = "ingestion_framework"
      location           = var.global_settings.location
      vnet_key           = "vnet"
      subnet_key         = "private_endpoints"

      private_service_connection = {
        name                 = "ingestion_sqls"
        is_manual_connection = false
        subresource_names    = ["sqlServer"]
      }

      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.database.windows.net"]
      }
    }
  }

  data_factory = {
    ingestion = {
      name                            = "lz-adf-ingestion"
      resource_group_key              = "ingestion_framework"
      managed_virtual_network_enabled = true
      enable_system_msi               = true

      diagnostic_profiles = {
        central_logs_region1 = {
          definition_key   = "azure_data_factory"
          destination_type = "log_analytics"
          destination_key  = "central_logs"
        }
      }

      private_endpoints = {
        df_if-factory = {
          name               = "adf-lzif-acct"
          subnet_key         = "private_endpoints"
          resource_group_key = "ingestion_framework"

          private_service_connection = {
            name              = "adf-lzint-acct"
            subresource_names = ["dataFactory"]
          }

          private_dns = {
            zone_group_name = "default"
            keys            = ["privatelink.datafactory.azure.net"]
          }
        }
        df_shared-portal = {
          name               = "adf-lzif-portal"
          subnet_key         = "private_endpoints"
          resource_group_key = "ingestion_framework"

          private_service_connection = {
            name              = "adf-lzif-portal"
            subresource_names = ["portal"]
          }

          private_dns = {
            zone_group_name = "default"
            keys            = ["privatelink.adf.azure.com"]
          }
        }
      }
    }
  }



}
