
module "keyvault" {
  source   = "../../services/general/keyvault/keyvault"
  for_each = local.keyvaults

  global_settings       = var.global_settings
  settings              = each.value
  location              = var.global_settings.location
  resource_group_name   = var.combined_objects_core.resource_groups[each.value.resource_group_key].name
  name                  = "${var.global_settings.name}-${each.value.name}"
  tags                  = try(var.tags, {})
  combined_objects_core = var.combined_objects_core
}
