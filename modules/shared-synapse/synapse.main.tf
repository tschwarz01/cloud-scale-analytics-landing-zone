resource "random_password" "sql_admin" {
  count = try(local.synapse_workspaces["synapse_workspace_shared"].sql_administrator_login_password, null) == null ? 1 : 0

  length           = 128
  special          = true
  upper            = true
  numeric          = true
  override_special = "$#%"
}


module "keyvault" {
  source   = "../../services/general/keyvault/keyvault"
  for_each = local.keyvaults

  name                  = try(each.value.name, "syn-secrets")
  global_settings       = var.global_settings
  settings              = each.value
  location              = var.global_settings.location
  resource_group_name   = can(each.value.resource_group.name) || can(each.value.resource_group_name) ? try(each.value.resource_group.name, each.value.resource_group_name) : var.combined_objects_core.resource_groups[try(each.value.resource_group_key, each.value.resource_group.key)].name
  tags                  = try(var.tags, {})
  combined_objects_core = var.combined_objects_core
}


resource "azurerm_role_assignment" "role_assignment" {
  depends_on = [module.keyvault]
  for_each   = local.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}


resource "azurerm_key_vault_secret" "sql_admin_password" {
  count = try(local.synapse_workspaces["synapse_workspace_shared"].sql_administrator_login_password, null) == null ? 1 : 0

  name         = "shared-synapse-sql-admin-password"
  value        = random_password.sql_admin.0.result
  key_vault_id = module.keyvault["synapse"].id

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}


resource "azurerm_key_vault_secret" "sql_admin" {
  count = try(local.synapse_workspaces["synapse_workspace_shared"].sql_administrator_login_password, null) == null ? 1 : 0

  name         = "shared-synapse-sql-admin-username"
  value        = local.synapse_workspaces["synapse_workspace_shared"].sql_administrator_login
  key_vault_id = module.keyvault["synapse"].id
}

resource "azurerm_key_vault_secret" "synapse_name" {
  count = try(local.synapse_workspaces["synapse_workspace_shared"].sql_administrator_login_password, null) == null ? 1 : 0

  name         = "shared-synapse-name"
  value        = "${var.global_settings.name}-${local.synapse_workspaces["synapse_workspace_shared"].name}"
  key_vault_id = module.keyvault["synapse"].id
}


resource "azurerm_key_vault_secret" "synapse_rg_name" {
  count = try(local.synapse_workspaces["synapse_workspace_shared"].sql_administrator_login_password, null) == null ? 1 : 0

  name         = "shared-synapse-resource-group-name"
  value        = var.combined_objects_core.resource_groups[local.synapse_workspaces["synapse_workspace_shared"].resource_group_key].name
  key_vault_id = module.keyvault["synapse"].id
}


resource "azurerm_synapse_workspace" "ws" {
  for_each = local.synapse_workspaces

  name                                 = "${var.global_settings.name}-${each.value.name}"
  resource_group_name                  = can(each.value.resource_group_name) ? each.value.resource_group_name : var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  location                             = var.global_settings.location
  storage_data_lake_gen2_filesystem_id = var.module_settings.synapse_gen2_filesystem_id
  sql_administrator_login              = try(each.value.sql_administrator_login, "dbadmin")
  sql_administrator_login_password     = try(each.value.sql_administrator_login_password, random_password.sql_admin.0.result)
  managed_virtual_network_enabled      = try(each.value.managed_virtual_network_enabled, false)
  sql_identity_control_enabled         = try(each.value.sql_identity_control_enabled, null)
  managed_resource_group_name          = try(each.value.managed_resource_group_name, null)
  tags                                 = try(var.tags, {})

  identity {
    type = "SystemAssigned"
  }

  dynamic "aad_admin" {
    for_each = try(each.value.aad_admin, {}) == {} ? [] : [1]

    content {
      login     = each.value.aad_admin.login
      object_id = each.value.aad_admin.object_id
      tenant_id = each.value.aad_admin.tenant_id
    }
  }

  dynamic "sql_aad_admin" {
    for_each = try(each.value.sql_aad_admin, {}) == {} ? [] : [1]

    content {
      login     = each.value.sql_aad_admin.login
      object_id = each.value.sql_aad_admin.object_id
      tenant_id = each.value.sql_aad_admin.tenant_id
    }
  }

  dynamic "azure_devops_repo" {
    for_each = try(each.value.azure_devops_repo, {})

    content {
      account_name    = each.value.azure_devops_repo.account_name
      branch_name     = each.value.azure_devops_repo.branch_name
      project_name    = each.value.azure_devops_repo.project_name
      repository_name = each.value.azure_devops_repo.branch_name
      root_folder     = each.value.azure_devops_repo.root_folder
    }
  }

  dynamic "customer_managed_key" {
    for_each = try(each.value.customer_managed_key_versionless_id, null) == null ? [] : [1]

    content {
      key_versionless_id = try(each.value.customer_managed_key_versionless_id, null)
    }
  }

  dynamic "github_repo" {
    for_each = try(each.value.github_repo, {})

    content {
      account_name    = each.value.github_repo.account_name
      branch_name     = each.value.github_repo.project_name
      repository_name = each.value.github_repo.branch_name
      root_folder     = each.value.github_repo.root_folder
      git_url         = each.value.github_repo.git_url
    }
  }
}


resource "azurerm_synapse_sql_pool" "sql_pool" {
  #for_each             = local.synapse_sql_pools
  for_each = { for k, v in local.synapse_sql_pools : k => v if var.module_settings.feature_flags.create_sql_pool == true }

  name                 = try(each.value.name, "sharedsynpool")
  synapse_workspace_id = azurerm_synapse_workspace.ws[each.value.synapse_workspace_key].id
  sku_name             = try(each.value.sku_name, "DW100c")
  create_mode          = try(each.value.create_mode, "Default")
  collation            = try(each.value.collation, null)
  data_encrypted       = try(each.value.data_encrypted, false)
  recovery_database_id = try(each.value.create_mode, null) == "Recovery" ? each.value.recovery_database_id : null
  tags                 = try(var.tags, {})

  dynamic "restore" {
    for_each = try(each.value.restore, {}) == {} ? [] : [1]

    content {
      source_database_id = try(each.value.restore.source_database_id)
      point_in_time      = try(each.value.restore.point_in_time)
    }
  }
}


resource "azurerm_synapse_spark_pool" "spark_pool" {
  #for_each = local.synapse_spark_pools
  for_each = { for k, v in local.synapse_spark_pools : k => v if var.module_settings.feature_flags.create_spark_pool == true }

  name                                = "${var.global_settings.prefix}${each.value.name}"
  synapse_workspace_id                = azurerm_synapse_workspace.ws[each.value.synapse_workspace_key].id
  node_size_family                    = each.value.node_size_family
  node_size                           = each.value.node_size
  node_count                          = try(each.value.node_count, null)
  cache_size                          = try(each.value.cache_size, null)
  compute_isolation_enabled           = try(each.value.node_size, null) == "XXXLarge" ? try(each.value.compute_isolation_enabled, null) : false
  dynamic_executor_allocation_enabled = try(each.value.dynamic_executor_allocation_enabled, null)
  session_level_packages_enabled      = try(each.value.session_level_packages_enabled, null)
  spark_log_folder                    = try(each.value.spark_log_folder, "/logs")
  spark_events_folder                 = try(each.value.spark_events_folder, "/events")
  spark_version                       = try(each.value.spark_version, "2.4")

  auto_scale {
    max_node_count = each.value.auto_scale.max_node_count
    min_node_count = each.value.auto_scale.min_node_count
  }

  auto_pause {
    delay_in_minutes = each.value.auto_pause.delay_in_minutes
  }

  dynamic "library_requirement" {
    for_each = try(each.value.library_requirement, {})

    content {
      content  = each.value.library_requirement.content
      filename = each.value.library_requirement.filename
    }
  }

  dynamic "spark_config" {
    for_each = try(each.value.spark_config, {})

    content {
      content  = try(each.value.spark_config.content, null)
      filename = try(each.value.spark_config.filename, null)
    }
  }
  tags = try(var.tags, {})
}


module "private_endpoints" {
  source   = "../../services/networking/private_endpoint"
  for_each = local.private_endpoints

  location                   = try(each.value.location, var.global_settings.location, null)
  resource_group_name        = try(each.value.resource_group_name, var.combined_objects_core.resource_groups[try(each.value.resource_group.key, each.value.resource_group_key)].name)
  resource_id                = each.value.resource_id
  name                       = "${var.global_settings.name}-${each.value.name}"
  private_service_connection = each.value.private_service_connection
  subnet_id                  = try(each.value.subnet_id, var.combined_objects_core.virtual_subnets[each.value.subnet_key].id)
  private_dns                = each.value.private_dns
  private_dns_zones          = var.combined_objects_core.private_dns_zones
  tags                       = try(var.tags, {})
}


module "ws_diagnostics" {
  source   = "../../services/logmon/diagnostics"
  for_each = azurerm_synapse_workspace.ws

  resource_id = each.value.id
  diagnostics = var.combined_objects_core.diagnostics
  profiles    = local.synapse_workspaces[each.key].diagnostic_profiles
}


module "sql_pool_diagnostics" {
  source   = "../../services/logmon/diagnostics"
  for_each = azurerm_synapse_sql_pool.sql_pool

  resource_id = each.value.id
  diagnostics = var.combined_objects_core.diagnostics
  profiles    = local.synapse_sql_pools[each.key].diagnostic_profiles
}


module "spark_pool_diagnostics" {
  source   = "../../services/logmon/diagnostics"
  for_each = azurerm_synapse_spark_pool.spark_pool

  resource_id = each.value.id
  diagnostics = var.combined_objects_core.diagnostics
  profiles    = local.synapse_spark_pools[each.key].diagnostic_profiles
}
