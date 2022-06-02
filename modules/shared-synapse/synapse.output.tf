
output "synapse_spark_pools" {
  value = try(azurerm_synapse_spark_pool.spark_pool, {})
}

output "synapse_sql_pools" {
  value = try(azurerm_synapse_sql_pool.sql_pool, {})
}

output "synapse_workspaces" {
  value = try(azurerm_synapse_workspace.ws, {})
}

output "keyvaults" {
  value = module.keyvault
}

output "private_endpoints" {
  value = module.private_endpoints
}
