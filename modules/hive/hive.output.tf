output "keyvaults" {
  value = module.keyvault
}

output "azure_sql_servers" {
  value = azurerm_mssql_server.sqls
}

output "azure_sql_databases" {
  value = azurerm_mssql_database.mssqldb
}

output "private_endpoints" {
  value = module.private_endpoints
}
