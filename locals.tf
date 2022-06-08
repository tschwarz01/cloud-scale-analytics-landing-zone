resource "random_string" "prefix" {
  count   = try(var.global_settings.prefix, null) == null ? 1 : 0
  length  = 4
  special = false
  upper   = false
  numeric = false
}


locals {

  global_settings = {
    location    = var.location
    prefix      = random_string.prefix[0].result
    environment = var.environment
    name        = lower("${random_string.prefix[0].result}-${var.environment}")
    name_clean  = lower("${random_string.prefix[0].result}${var.environment}")
    tags        = merge(local.base_tags, var.tags, {})

    client_config = {
      client_id               = data.azurerm_client_config.default.client_id
      tenant_id               = data.azurerm_client_config.default.tenant_id
      subscription_id         = data.azurerm_subscription.current.id
      object_id               = data.azurerm_client_config.default.object_id == null || data.azurerm_client_config.default.object_id == "" ? data.azuread_client_config.current.object_id : null
      logged_user_objectId    = data.azurerm_client_config.default.object_id == null || data.azurerm_client_config.default.object_id == "" ? data.azuread_client_config.current.object_id : null
      logged_aad_app_objectId = data.azurerm_client_config.default.object_id == null || data.azurerm_client_config.default.object_id == "" ? data.azuread_client_config.current.object_id : null
    }
  }


  base_tags = {
    Solution = "CAF Cloud Scale Analytics"
    Project  = "Data Landing Zone"
    Toolkit  = "Terraform"
  }


  core_module_settings = {
    connectivity_hub_virtual_network_id         = local.dmlz_config.hub_vnet_id
    data_management_zone_virtual_network_id     = local.dmlz_config.dmlz_vnet_id
    remote_log_analytics_workspace_resource_id  = local.dmlz_config.central_law_resource_id
    remote_log_analytics_workspace_workspace_id = local.dmlz_config.central_law_id
    vnet_address_cidr                           = var.vnet_address_cidr
    services_subnet_cidr                        = var.services_subnet_cidr
    private_endpoint_subnet_cidr                = var.private_endpoint_subnet_cidr
    shared_databricks_pub_subnet_cidr           = var.shared_databricks_pub_subnet_cidr
    shared_databricks_pri_subnet_cidr           = var.shared_databricks_pri_subnet_cidr
    aml_training_subnet_cidr                    = try(var.aml_training_subnet_cidr, null)
    private_dns_zones                           = local.dmlz_config.private_dns_zones #local.dmlz_config.private_dns_zones #var.remote_private_dns_zones
  }


  dbmon_module_settings = {}


  hive_module_settings = {}


  datalake_module_settings = {
    adls_account_tier             = var.adls_account_tier
    adls_account_replication_type = var.adls_account_replication_type
  }


  extdata_module_settings = {}


  integration_module_settings = {
    use_existing_shared_runtime_compute                   = try(local.dmlz_config.shir_compute_deployed_to_dmlz, false) == false ? false : try(var.use_existing_shared_runtime_compute, false)
    remote_data_factory_resource_id                       = local.dmlz_config.dmlz_factory_id
    remote_data_factory_self_hosted_runtime_resource_id   = local.dmlz_config.dmlz_shir_id
    create_shared_runtime_compute_in_landing_zone         = try(var.create_shared_runtime_compute_in_landing_zone, false)
    data_factory_self_hosted_runtime_authorization_script = try(var.data_factory_self_hosted_runtime_authorization_script, null)
    vmss_vm_sku                                           = var.vmss_vm_sku
    vmss_instance_count                                   = var.vmss_instance_count
  }


  ingestion_module_settings = {}


  databricks_module_settings = {
    databricks_ws_sku = var.databricks_ws_sku
  }


  synapse_module_settings = {
    synapse_gen2_filesystem_id   = module.datalake_services.gen2_filesystems["shared_synaspe"].id
    synapse_sql_pool_sku         = var.synapse_sql_pool_sku
    synapse_spark_node_size      = var.synapse_spark_node_size
    synapse_spark_min_node_count = var.synapse_spark_min_node_count
    synapse_spark_max_node_count = var.synapse_spark_max_node_count
    feature_flags = {
      create_sql_pool   = var.deploy_shared_synapse_workspace == true && var.deploy_shared_synapse_sql_pool == true ? true : false
      create_spark_pool = var.deploy_shared_synapse_workspace == true && var.deploy_shared_synapse_spark_pool == true ? true : false
    }
  }


  combined_objects_core = {
    resource_groups         = merge(module.core.resource_groups, {})
    virtual_networks        = merge(module.core.virtual_networks, {})
    virtual_subnets         = merge(module.core.virtual_subnets, {})
    network_security_groups = merge(module.core.network_security_groups, {})
    private_dns_zones       = local.dmlz_config.private_dns_zones
    diagnostics             = module.core.diagnostics
  }


  module_flags = {
    databricks = {
      name    = "shared_databricks"
      enabled = var.deploy_shared_databricks_workspace
    }
    synapse = {
      name    = "shared_synapse"
      enabled = var.deploy_shared_synapse_workspace
    }
  }

  remote_private_dns_zones = try(var.dns_zones_remote_zones, null) != null ? {
    for zone in var.dns_zones_remote_zones : zone => "/subscriptions/${var.dns_zones_remote_subscription_id}/resourceGroups/${var.dns_zones_remote_resource_group}/providers/Microsoft.Network/privateDnsZones/${zone}"
  if var.dns_zones_remote_zones != null } : {}

  dmlz_input = data.terraform_remote_state.dmlz.outputs.dlz_params

  dmlz_config = {
    hub_vnet_id                   = try(var.connectivity_hub_virtual_network_id, null) == null ? try(local.dmlz_input.connectivity_hub_vnet_id, null) : var.connectivity_hub_virtual_network_id
    dmlz_subscription_id          = try(var.data_management_zone_virtual_network_id, null) == null ? try(element(split("/", local.dmlz_input.mgmt_zone_vnet_id), 2), null) : element(split("/", var.data_management_zone_virtual_network_id), 2)
    dmlz_vnet_id                  = try(var.data_management_zone_virtual_network_id, null) == null ? try(local.dmlz_input.mgmt_zone_vnet_id, null) : var.data_management_zone_virtual_network_id
    dmlz_vnet_cidr                = try(local.dmlz_input.mgmt_zone_vnet_cidr, [])
    central_law_id                = try(var.remote_log_analytics_workspace_workspace_id, null) == null ? try(local.dmlz_input.log_analytics_workspace_workspace_id, null) : var.remote_log_analytics_workspace_workspace_id
    central_law_resource_id       = try(var.remote_log_analytics_workspace_resource_id, null) == null ? try(local.dmlz_input.log_analytics_workspace_resource_id, null) : var.remote_log_analytics_workspace_resource_id
    shir_compute_deployed_to_dmlz = try(local.dmlz_input.deploy_dmlz_shared_integration_runtime, null)
    dmlz_factory_id               = try(var.remote_data_factory_resource_id, null) == null ? try(local.dmlz_input.mgmt_zone_factory_id, null) : var.remote_data_factory_resource_id
    dmlz_shir_id                  = try(var.remote_data_factory_self_hosted_runtime_resource_id, null) == null ? try(local.dmlz_input.mgmt_zone_shir_id, null) : var.remote_data_factory_self_hosted_runtime_resource_id
    private_dns_zones             = try(var.dns_zones_remote_zones, null) == null ? try(local.dmlz_input.private_dns_zones, null) : local.remote_private_dns_zones
    #private_dns_zones             = try(local.remote_private_dns_zones, local.dmlz_input.private_dns_zones)
  }





}
