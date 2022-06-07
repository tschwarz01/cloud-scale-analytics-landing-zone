locals {
  keyvaults = {
    integration = {
      name                      = "lzintegration18"
      location                  = var.global_settings.location
      resource_group_key        = "integration"
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
          name               = "lzkvint"
          resource_group_key = "integration"
          location           = var.global_settings.location
          vnet_key           = "vnet"
          subnet_key         = "private_endpoints"

          private_service_connection = {
            name                 = "lzkvint"
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

  data_factory = {
    df_shared = {
      name                            = "lz-adf-shared"
      resource_group_name             = var.combined_objects_core.resource_groups["integration"].name
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
        df_shared-factory = {
          name               = "adf-int-acct"
          subnet_key         = "private_endpoints"
          resource_group_key = "integration"

          private_service_connection = {
            name                 = "adf-lzint-acct"
            is_manual_connection = false
            subresource_names    = ["dataFactory"]
          }

          private_dns = {
            zone_group_name = "privatelink.datafactory.azure.net"
            keys            = ["privatelink.datafactory.azure.net"]
          }
        }
        df_shared-portal = {
          name               = "adf-lzint-portal"
          subnet_key         = "private_endpoints"
          resource_group_key = "integration"

          private_service_connection = {
            name                 = "adf-lzint-portal"
            is_manual_connection = false
            subresource_names    = ["portal"]
          }

          private_dns = {
            zone_group_name = "privatelink.adf.azure.com"
            keys            = ["privatelink.adf.azure.com"]
          }
        }
      }
    }
  }

  role_assignments = {
    kvint = {
      scope                = try(module.keyvault["integration"].id, null)
      role_definition_name = "Key Vault Secrets Officer"
      principal_id         = var.global_settings.client_config.object_id
    }
  }

  data_factory_integration_runtimes_self_hosted = {
    shir_local = {
      name             = "local-shir"
      data_factory_key = "df_shared"
      description      = "Local Data Landing Zone Self-Hosted Integration Runtime"
      is_remote        = false
    }
    shir_remote = {
      name                                                = "remote-shir"
      data_factory_key                                    = "df_shared"
      description                                         = "Self-Hosted Integration Runtime using compute resources deployed remotely in the Data Management Landing Zone."
      remote_data_factory_resource_id                     = var.module_settings.remote_data_factory_resource_id
      remote_data_factory_self_hosted_runtime_resource_id = var.module_settings.remote_data_factory_self_hosted_runtime_resource_id
      is_remote                                           = true
    }
  }

  vmss_self_hosted_integration_runtimes = {
    vmss01 = {
      data_factory_self_hosted_runtime_authorization_script = var.module_settings.data_factory_self_hosted_runtime_authorization_script
      resource_group_key                                    = "integration"
      data_factory_key                                      = "df_shared"
      integration_runtime_key                               = "shir_local"
      vnet_key                                              = "vnet"
      subnet_key                                            = "services"
      keyvault_key                                          = "integration"
      boot_diagnostics_storage_account_key                  = "bootdiag1"

      vmss_settings = {
        windows = {
          provision_vm_agent = true
          admin_username     = "adminuser"
          name               = "lzshir"
          sku                = "Standard_D4d_v4"
          priority           = "Spot"
          eviction_policy    = "Deallocate"
          instances          = 2
        }
      }
    }
  }
}
