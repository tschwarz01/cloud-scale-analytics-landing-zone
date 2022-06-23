
module "keyvault" {
  source   = "../../services/general/keyvault/keyvault"
  for_each = lookup(var.module_settings, "create_shared_runtime_compute_in_landing_zone", false) == true ? local.keyvaults : {}

  name                  = "${var.global_settings.name}-${each.value.name}"
  global_settings       = var.global_settings
  settings              = each.value
  location              = var.global_settings.location
  resource_group_name   = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  tags                  = var.tags
  combined_objects_core = var.combined_objects_core
}


module "data_factory" {
  source   = "../../services/general/data_factory/data_factory"
  for_each = local.data_factory

  name                  = "${var.global_settings.name}-${each.value.name}"
  global_settings       = var.global_settings
  settings              = each.value
  location              = var.global_settings.location
  resource_group_name   = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  tags                  = var.tags
  combined_objects_core = var.combined_objects_core
}

module "remote_self_hosted_runtimes" {
  depends_on = [azurerm_role_assignment.remote_shared_factory_assignment]
  source     = "../../services/general/data_factory/integration_runtime_self_hosted"
  for_each = {
    for key, value in local.data_factory_integration_runtimes_self_hosted : key => value
    if value.is_remote == true && var.module_settings.use_existing_shared_runtime_compute == true
  }

  name        = each.value.name
  description = lookup(each.value, "description", null)
  #data_factories  = module.data_factory
  data_factory_id = module.data_factory[each.value.data_factory_key].id
  settings        = each.value
}

module "local_self_hosted_runtimes" {
  source = "../../services/general/data_factory/integration_runtime_self_hosted"
  for_each = {
    for key, value in local.data_factory_integration_runtimes_self_hosted : key => value
    if value.is_remote == false && var.module_settings.create_shared_runtime_compute_in_landing_zone == true
  }

  name        = each.value.name
  description = lookup(each.value, "description", null)
  #data_factories  = module.data_factory
  data_factory_id = module.data_factory[each.value.data_factory_key].id
  settings        = each.value
}

resource "azurerm_role_assignment" "remote_shared_factory_assignment" {
  for_each = {
    for key, value in local.data_factory_integration_runtimes_self_hosted : key => value
    if value.is_remote == true && var.module_settings.use_existing_shared_runtime_compute == true
  }

  scope                = each.value.remote_data_factory_resource_id
  role_definition_name = "Contributor"
  principal_id         = module.data_factory[each.value.data_factory_key].identity[0].principal_id
}


resource "azurerm_role_assignment" "role_assignment" {
  depends_on = [module.keyvault]
  for_each = {
    for key, value in local.role_assignments : key => value
    if var.module_settings.create_shared_runtime_compute_in_landing_zone == true
  }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}


resource "time_sleep" "shirdelay" {
  depends_on      = [azurerm_role_assignment.role_assignment]
  create_duration = "15s"
}


module "vmss_self_hosted_integration_runtime" {
  depends_on = [time_sleep.shirdelay]
  source     = "../../services/general/data_factory/vmss_shir"
  for_each   = lookup(var.module_settings, "create_shared_runtime_compute_in_landing_zone", false) == true ? local.vmss_self_hosted_integration_runtimes : {}

  global_settings        = var.global_settings
  resource_group_name    = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  location               = var.global_settings.location
  combined_objects_core  = var.combined_objects_core
  custom_script_fileuri  = each.value.data_factory_self_hosted_runtime_authorization_script
  shir_authorization_key = module.local_self_hosted_runtimes[each.value.integration_runtime_key].primary_authorization_key
  keyvaults              = module.keyvault
  keyvault_id            = module.keyvault["integration"].id
  settings               = each.value
  tags                   = var.tags
}
