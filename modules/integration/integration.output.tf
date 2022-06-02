output "data_factories" {
  value = module.data_factory
}

output "keyvaults" {
  value = module.keyvault
}

output "self_hosted_integration_runtimes" {
  value = merge(module.remote_self_hosted_runtimes, module.local_self_hosted_runtimes)
}

output "virtual_machine_scale_set_shir_compute" {
  value = module.vmss_self_hosted_integration_runtime
}
