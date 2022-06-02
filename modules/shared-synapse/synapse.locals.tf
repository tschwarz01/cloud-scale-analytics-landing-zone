locals {

  keyvaults = {
    synapse = {
      name                      = "syn-secrets"
      location                  = var.global_settings.location
      resource_group_key        = "synapse"
      sku_name                  = "standard"
      enable_rbac_authorization = true
      soft_delete_enabled       = true
      purge_protection_enabled  = false

      diagnostic_profiles = {
        central_logs_region1 = {
          definition_key   = "azure_key_vault"
          destination_type = "log_analytics"
          destination_key  = "central_logs"
        }
      }

      private_endpoints = {
        vault = {
          name               = "lzkvsyn"
          resource_group_key = "synapse"
          location           = var.global_settings.location
          vnet_key           = "vnet"
          subnet_key         = "private_endpoints"

          private_service_connection = {
            name                 = "lzkvsyn"
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


  role_assignments = {
    kvsyn = {
      scope                = try(module.keyvault["synapse"].id, null)
      role_definition_name = "Key Vault Secrets Officer"
      principal_id         = var.global_settings.client_config.object_id
    }
  }


  synapse_workspaces = {
    synapse_workspace_shared = {
      name                    = "syn-shared-ws"
      resource_group_key      = "synapse"
      sql_administrator_login = "dbadmin"
      # sql_administrator_login_password = "<string password>"   # If not set use module autogenerate a strong password and stores it in the keyvault
      keyvault_key                    = "synapse"
      managed_virtual_network_enabled = true
      data_encrypted                  = true

      aad_admin = {
        login     = "thosch@microsoft.com"
        object_id = var.global_settings.client_config.object_id
        tenant_id = var.global_settings.client_config.tenant_id
      }

      sql_aad_admin = {
        login     = "thosch@microsoft.com"
        object_id = var.global_settings.client_config.object_id
        tenant_id = var.global_settings.client_config.tenant_id
      }

      diagnostic_profiles = {
        synapsews = {
          definition_key   = "synapse_workspace"
          destination_type = "log_analytics"
          destination_key  = "central_logs"
        }
      }
    }
  }


  synapse_sql_pools = {
    shared_synapse_sql_pool = {
      name                  = "sharedsynpool"
      synapse_workspace_key = "synapse_workspace_shared"
      sku_name              = var.module_settings.synapse_sql_pool_sku
      create_mode           = "Default"

      diagnostic_profiles = {
        synapse_sql = {
          definition_key   = "synapse_sql_pool"
          destination_type = "log_analytics"
          destination_key  = "central_logs"
        }
      }
    }
  }


  synapse_spark_pools = {
    shared_synapse_spark_pool = {
      name                  = "synspark" #[name can contain only letters or numbers, must start with a letter, and be between 1 and 15 characters long]
      synapse_workspace_key = "synapse_workspace_shared"
      node_size_family      = "MemoryOptimized" # Only current option
      node_size             = var.module_settings.synapse_spark_node_size
      cache_size            = 20 # Percentage of disk to reserve for cache
      spark_version         = "3.1"

      auto_scale = {
        max_node_count = var.module_settings.synapse_spark_max_node_count
        min_node_count = var.module_settings.synapse_spark_min_node_count
      }

      auto_pause = {
        delay_in_minutes = 15
      }

      tags = {
        environment = "example tag"
      }

      diagnostic_profiles = {
        synapse_spark = {
          definition_key   = "synapse_spark_pool"
          destination_type = "log_analytics"
          destination_key  = "central_logs"
        }
      }
    }
  }


  private_endpoints = {
    sql = {
      resource_id        = azurerm_synapse_workspace.ws["synapse_workspace_shared"].id
      name               = "sharedsynapsesql"
      vnet_key           = "vnet"
      subnet_key         = "private_endpoints"
      resource_group_key = "synapse"

      private_service_connection = {
        name                 = "sharedsynapsesql"
        is_manual_connection = false
        subresource_names    = ["Sql"]
      }

      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.sql.azuresynapse.net"]
      }
    }

    sqlod = {
      resource_id        = azurerm_synapse_workspace.ws["synapse_workspace_shared"].id
      name               = "sharedsynapsesqlod"
      vnet_key           = "vnet"
      subnet_key         = "private_endpoints"
      resource_group_key = "synapse"

      private_service_connection = {
        name                 = "sharedsynapsesqlod"
        is_manual_connection = false
        subresource_names    = ["SqlOnDemand"]
      }

      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.sql.azuresynapse.net"]
      }
    }

    dev = {
      resource_id        = azurerm_synapse_workspace.ws["synapse_workspace_shared"].id
      name               = "sharedsynapsedev"
      vnet_key           = "vnet"
      subnet_key         = "private_endpoints"
      resource_group_key = "synapse"

      private_service_connection = {
        name                 = "sharedsynapsedev"
        is_manual_connection = false
        subresource_names    = ["Dev"]
      }

      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.dev.azuresynapse.net"]
      }
    }
  }

}
