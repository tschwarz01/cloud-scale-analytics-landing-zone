
output "storage_accounts" {
  value = azurerm_storage_account.stg
}

output "storage_containers" {
  value = azurerm_storage_container.container
}

output "private_endpoints" {
  value = module.private_endpoints
}
