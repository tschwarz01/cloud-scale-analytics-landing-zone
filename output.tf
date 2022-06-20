
output "combined_objects_core" {
  value = local.combined_objects_core
}


output "datalake_services" {
  value     = module.datalake_services
  sensitive = true
}
