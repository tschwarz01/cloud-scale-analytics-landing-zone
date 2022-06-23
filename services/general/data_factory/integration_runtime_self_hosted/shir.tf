
resource "azurerm_data_factory_integration_runtime_self_hosted" "shir" {
  data_factory_id = var.data_factory_id
  name            = var.name
  description     = var.description

  dynamic "rbac_authorization" {
    for_each = lookup(var.settings, "remote_data_factory_self_hosted_runtime_resource_id", var.id) == null ? [] : [1]
    content {
      resource_id = lookup(var.settings, "remote_data_factory_self_hosted_runtime_resource_id", var.id)
    }
  }
}

