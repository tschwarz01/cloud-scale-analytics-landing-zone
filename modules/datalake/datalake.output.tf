output "storage_accounts" {
  value = azurerm_storage_account.adls
}

output "gen2_filesystems" {
  value = azurerm_storage_data_lake_gen2_filesystem.gen2
}

output "private_endpoints" {
  value = module.private_endpoints
}
