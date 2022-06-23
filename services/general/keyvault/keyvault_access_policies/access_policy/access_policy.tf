
resource "azurerm_key_vault_access_policy" "policy" {
  key_vault_id            = var.keyvault_id
  tenant_id               = var.tenant_id
  object_id               = var.object_id
  key_permissions         = lookup(var.access_policy, "key_permissions", null)
  secret_permissions      = lookup(var.access_policy, "secret_permissions", null)
  certificate_permissions = lookup(var.access_policy, "certificate_permissions", null)
  storage_permissions     = lookup(var.access_policy, "storage_permissions", null)

  timeouts {
    delete = "60m"
  }

  lifecycle {
    ignore_changes = [key_vault_id, object_id]
  }
}


output "id" {
  value = azurerm_key_vault_access_policy.policy.id
}

output "object_id" {
  value = azurerm_key_vault_access_policy.policy.object_id
}

output "secret_permissions" {
  value = azurerm_key_vault_access_policy.policy.secret_permissions
}
