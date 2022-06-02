
resource "azurerm_data_factory_integration_runtime_self_hosted" "shir" {
  data_factory_id = var.data_factory_id
  name            = var.name
  description     = try(var.description, null)

  dynamic "rbac_authorization" {
    for_each = try(var.settings.remote_data_factory_self_hosted_runtime_resource_id, var.id, null) == null ? [] : [1]
    content {
      resource_id = try(var.settings.remote_data_factory_self_hosted_runtime_resource_id, var.id, null)
    }
  }
}

