
locals {

  resource_groups = {

    network = {
      name     = "network"
      location = var.global_settings.location
    }

    databricks_monitoring = {
      name     = "databricks-monitoring"
      location = var.global_settings.location
    }

    hive_metastore = {
      name     = "hive-metastore"
      location = var.global_settings.location
    }

    adls = {
      name     = "datalake-services"
      location = var.global_settings.location
    }

    upload_ingestion = {
      name     = "external-data-landing"
      location = var.global_settings.location
    }

    ingestion_framework = {
      name     = "automated-ingestion-framework"
      location = var.global_settings.location
    }

    integration = {
      name     = "shared-integration"
      location = var.global_settings.location
    }

    cicd = {
      name     = "cicd-agents"
      location = var.global_settings.location
    }

    databricks = {
      name     = "shared-databricks"
      location = var.global_settings.location
    }

    synapse = {
      name     = "shared-synapse"
      location = var.global_settings.location
    }

    data_product01 = {
      name     = "data-product-analytics01"
      location = var.global_settings.location
    }
  }


  networking = {

    vnets = {
      vnet = {
        location           = var.global_settings.location
        resource_group_key = "network"

        vnet = {
          name          = "caf-csa-lz-vnet"
          address_space = [var.module_settings.vnet_address_cidr]
        }

        diagnostic_profiles = {

          vnets = {
            definition_key   = "networking_all"
            destination_type = "log_analytics"
            destination_key  = "central_logs"
          }
        }
      }
    }


    subnets = {

      services = {
        name     = "shared-services"
        cidr     = [var.module_settings.services_subnet_cidr]
        vnet_key = "vnet"
        nsg_key  = "empty_nsg"
      }


      private_endpoints = {
        name                                           = "private-endpoints"
        cidr                                           = [var.module_settings.private_endpoint_subnet_cidr]
        enforce_private_link_endpoint_network_policies = true
        vnet_key                                       = "vnet"
        nsg_key                                        = "empty_nsg"
      }


      databricks_pub = {
        name     = "shared-databricks-pub"
        cidr     = [var.module_settings.shared_databricks_pub_subnet_cidr]
        vnet_key = "vnet"

        delegation = {
          name               = "databricks-pub-delegation"
          service_delegation = "Microsoft.Databricks/workspaces"

          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action",
            "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
            "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
          ]
        }
      }


      databricks_pri = {
        name     = "shared-databricks-pri"
        cidr     = [var.module_settings.shared_databricks_pri_subnet_cidr]
        vnet_key = "vnet"

        delegation = {
          name               = "databricks-pri-delegation"
          service_delegation = "Microsoft.Databricks/workspaces"

          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action",
            "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
            "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
          ]
        }
      }


      aml_training = {
        name     = "aml-training"
        cidr     = [var.module_settings.aml_training_subnet_cidr]
        vnet_key = "vnet"
        nsg_key  = "aml_nsg"
      }
    }


    network_security_groups = {

      empty_nsg = {
        version            = 1
        resource_group_key = "network"
        location           = var.global_settings.location
        name               = "empty_nsg"
        nsg                = []
      }


      databricks_pub = {
        version            = 1
        resource_group_key = "network"
        location           = var.global_settings.location
        name               = "databricks-pub-nsg"
        nsg                = []
      }


      databricks_pri = {
        version            = 1
        resource_group_key = "network"
        location           = var.global_settings.location
        name               = "databricks-pri-nsg"
        nsg                = []
      }


      aml_nsg = {
        version            = 1
        resource_group_key = "network"
        location           = var.global_settings.location
        name               = "aml-training-nsg"

        nsg = [
          {
            name                       = "aml_allow_44224",
            priority                   = "100"
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "44224"
            source_address_prefix      = "AzureMachineLearning"
            destination_address_prefix = "*"
          },
          {
            name                       = "aml_allow_29876_29877",
            priority                   = "110"
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "29876-29877"
            source_address_prefix      = "BatchNodeManagement"
            destination_address_prefix = "*"
          }
        ]
      }
    }


    vnet_peerings = {

      lz_to_hub = {
        name                         = "dlz_to_connectivity_hub"
        from                         = { vnet_key = "vnet" }
        to                           = { remote_virtual_network_id = var.module_settings.connectivity_hub_virtual_network_id }
        allow_virtual_network_access = true
        allow_forwarded_traffic      = true
        allow_gateway_transit        = false
        use_remote_gateways          = true
      }

      hub_to_lz = {
        name                         = "region1_connectivity_hub_to_dlz"
        from                         = { id = var.module_settings.connectivity_hub_virtual_network_id }
        to                           = { vnet_key = "vnet" }
        allow_virtual_network_access = true
        allow_forwarded_traffic      = true
        allow_gateway_transit        = true
        use_remote_gateways          = false
      }

      lz_to_dmlz = {
        name                         = "dlz_to_dmlz"
        from                         = { vnet_key = "vnet" }
        to                           = { remote_virtual_network_id = var.module_settings.data_management_zone_virtual_network_id }
        allow_virtual_network_access = true
        allow_forwarded_traffic      = true
        allow_gateway_transit        = false
        use_remote_gateways          = false
      }

      dmlz_to_lz = {
        name                         = "dmlz_to_dlz"
        from                         = { id = var.module_settings.data_management_zone_virtual_network_id }
        to                           = { vnet_key = "vnet" }
        allow_virtual_network_access = true
        allow_forwarded_traffic      = true
        allow_gateway_transit        = false
        use_remote_gateways          = false
      }
    }
  }


  diagnostics = {
    diagnostic_log_analytics = local.diagnostic_log_analytics
  }


  combined_diagnostics = {
    diagnostics_definition   = local.diagnostics_definition
    diagnostics_destinations = local.diagnostics_destinations
    log_analytics            = module.diagnostic_log_analytics
  }


  diagnostic_log_analytics = {

    databricks_monitoring_region1 = {
      region             = "region1"
      name               = "databricks-monitoring"
      resource_group_key = "databricks_monitoring"
    }
  }


  diagnostics_destinations = {
    log_analytics = {

      central_logs = {
        workspace_id              = var.module_settings.remote_log_analytics_workspace_workspace_id
        log_analytics_resource_id = var.module_settings.remote_log_analytics_workspace_resource_id
      }

      databricks_monitoring = {
        log_analytics_key = "databricks_monitoring_region1"
      }
    }
  }

}


