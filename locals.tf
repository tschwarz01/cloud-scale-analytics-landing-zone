resource "random_string" "prefix" {
  count   = try(var.global_settings.prefix, null) == null ? 1 : 0
  length  = 4
  special = false
  upper   = false
  number  = false
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
    connectivity_hub_virtual_network_id         = var.connectivity_hub_virtual_network_id
    data_management_zone_virtual_network_id     = var.data_management_zone_virtual_network_id
    remote_log_analytics_workspace_resource_id  = var.remote_log_analytics_workspace_resource_id
    remote_log_analytics_workspace_workspace_id = var.remote_log_analytics_workspace_workspace_id
    vnet_address_cidr                           = var.vnet_address_cidr
    services_subnet_cidr                        = var.services_subnet_cidr
    private_endpoint_subnet_cidr                = var.private_endpoint_subnet_cidr
    shared_databricks_pub_subnet_cidr           = var.shared_databricks_pub_subnet_cidr
    shared_databricks_pri_subnet_cidr           = var.shared_databricks_pri_subnet_cidr
    private_dns_zones_subscription_id           = try(var.private_dns_zones_subscription_id, null)
    private_dns_zones_resource_group_name       = try(var.private_dns_zones_resource_group_name, null)
    remote_private_dns_zones                    = try(var.remote_private_dns_zones, null)
    aml_training_subnet_cidr                    = try(var.aml_training_subnet_cidr, null)
  }

  dbmon_module_settings = {}

  hive_module_settings = {}

  datalake_module_settings = {
    adls_account_tier             = var.adls_account_tier
    adls_account_replication_type = var.adls_account_replication_type
  }

  extdata_module_settings = {}

  integration_module_settings = {
    use_existing_shared_runtime_compute                   = try(var.use_existing_shared_runtime_compute, false)
    remote_data_factory_resource_id                       = try(var.remote_data_factory_resource_id, null)
    remote_data_factory_self_hosted_runtime_resource_id   = try(var.remote_data_factory_self_hosted_runtime_resource_id, null)
    create_shared_runtime_compute_in_landing_zone         = try(var.create_shared_runtime_compute_in_landing_zone, false)
    data_factory_self_hosted_runtime_authorization_script = try(var.data_factory_self_hosted_runtime_authorization_script, null)
    vmss_vm_sku                                           = try(var.vmss_vm_sku, null)
    vmss_instance_count                                   = try(var.vmss_instance_count, null)
  }

  ingestion_module_settings = {}

  databricks_module_settings = {
    databricks_ws_sku = var.databricks_ws_sku
  }

  synapse_module_settings = {
    synapse_gen2_filesystem_id   = module.datalake_services.gen2_filesystems["shared_synaspe_filesystem"].id
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
    private_dns_zones       = module.core.remote_pdns
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

}
