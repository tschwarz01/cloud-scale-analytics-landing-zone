output "resource_groups" {
  value = azurerm_resource_group.rg
}
output "virtual_subnets" {
  value = local.subnets
}
output "virtual_networks" {
  value = azurerm_virtual_network.vnet
}
output "network_security_groups" {
  value = azurerm_network_security_group.nsg
}
output "remote_pdns" {
  #value = azapi_resource.remote_vnet_links.*.output
  value = {
    for key, val in azapi_resource.remote_vnet_links : key => {
      id        = val.id
      parent_id = val.parent_id
      name      = val.name
      #tags                 = val.tags
      registration_enabled = jsondecode(val.body).properties.registrationEnabled
      virtual_network_id   = jsondecode(val.body).properties.virtualNetwork.id

    }
  }
}
output "diagnostics" {
  value = local.combined_diagnostics
}
