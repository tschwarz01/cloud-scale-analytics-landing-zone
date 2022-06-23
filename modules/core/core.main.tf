terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 0.2.0"
    }
  }
}


resource "azurerm_resource_group" "rg" {
  for_each = local.resource_groups

  name     = "${var.global_settings.name}-${each.value.name}"
  location = each.value.location
  tags     = var.tags
}


resource "azurerm_network_security_group" "nsg" {
  for_each = local.networking.network_security_groups

  name                = "${var.global_settings.name}-${each.value.name}"
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  location            = each.value.location
  tags                = var.tags

  dynamic "security_rule" {
    for_each = lookup(each.value, "nsg", [])

    content {
      name                         = lookup(security_rule.value, "name", null)
      priority                     = lookup(security_rule.value, "priority", null)
      direction                    = lookup(security_rule.value, "direction", null)
      access                       = lookup(security_rule.value, "access", null)
      protocol                     = lookup(security_rule.value, "protocol", null)
      source_port_range            = lookup(security_rule.value, "source_port_range", null)
      source_port_ranges           = lookup(security_rule.value, "source_port_ranges", null)
      destination_port_range       = lookup(security_rule.value, "destination_port_range", null)
      destination_port_ranges      = lookup(security_rule.value, "destination_port_ranges", null)
      source_address_prefix        = lookup(security_rule.value, "source_address_prefix", null)
      source_address_prefixes      = lookup(security_rule.value, "source_address_prefixes", null)
      destination_address_prefix   = lookup(security_rule.value, "destination_address_prefix", null)
      destination_address_prefixes = lookup(security_rule.value, "destination_address_prefixes", null)
    }
  }
}


resource "azurerm_virtual_network" "vnet" {
  for_each = local.networking.vnets

  name                = "${var.global_settings.name}-${each.value.vnet.name}"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  address_space       = each.value.vnet.address_space
  tags                = var.tags
}


resource "azurerm_subnet" "snet" {
  for_each = local.networking.subnets

  name                 = "${var.global_settings.name}-${each.value.name}"
  resource_group_name  = azurerm_virtual_network.vnet[each.value.vnet_key].resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  address_prefixes     = each.value.cidr

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) == null ? [] : [each.value.delegation]

    content {
      name = lookup(delegation.value, "name")

      service_delegation {
        name    = lookup(delegation.value, "service_delegation")
        actions = lookup(delegation.value, "actions", null)
      }
    }
  }
}


resource "azurerm_subnet" "ssnet" {
  for_each = lookup(local.networking, "specialsubnets", {})

  name                 = each.value.name
  resource_group_name  = azurerm_virtual_network.vnet[each.value.vnet_key].resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet[each.value.vnet_key].name
  address_prefixes     = each.value.cidr

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) == null ? [] : [each.value.delegation]

    content {
      name = lookup(delegation.value, "name")

      service_delegation {
        name    = lookup(delegation.value, "service_delegation")
        actions = lookup(delegation.value, "actions", null)
      }
    }
  }
}


locals {
  combined_subnet_inputs = merge(lookup(local.networking, "subnets", {}), lookup(local.networking, "specialsubnets", {}))
  subnets                = merge(azurerm_subnet.snet, azurerm_subnet.ssnet, {})
}


resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  for_each = { for key, value in local.combined_subnet_inputs : key => value if can(value.nsg_key) == true }

  subnet_id                 = local.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg_key].id
}


resource "azurerm_route_table" "rt-training" {
  name                = "rt-training"
  location            = var.global_settings.location
  resource_group_name = azurerm_resource_group.rg["network"].name
}


resource "azurerm_route" "training-Internet-Route" {
  name                = "Internet"
  resource_group_name = azurerm_resource_group.rg["network"].name
  route_table_name    = azurerm_route_table.rt-training.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}


resource "azurerm_route" "training-AzureMLRoute" {
  name                = "AzureMLRoute"
  resource_group_name = azurerm_resource_group.rg["network"].name
  route_table_name    = azurerm_route_table.rt-training.name
  address_prefix      = "AzureMachineLearning"
  next_hop_type       = "Internet"
}


resource "azurerm_route" "training-BatchRoute" {
  name                = "BatchRoute"
  resource_group_name = azurerm_resource_group.rg["network"].name
  route_table_name    = azurerm_route_table.rt-training.name
  address_prefix      = "BatchNodeManagement"
  next_hop_type       = "Internet"
}


resource "azurerm_subnet_route_table_association" "rt-training-link" {
  subnet_id      = local.subnets["aml_training"].id
  route_table_id = azurerm_route_table.rt-training.id
}


resource "azapi_resource" "remote_vnet_links" {
  for_each  = lookup(var.module_settings, "private_dns_zones", {})
  type      = "Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01"
  location  = "global"
  name      = "${var.global_settings.name}-${each.key}"
  parent_id = each.value

  body = jsonencode({
    properties = {
      registrationEnabled = false
      virtualNetwork = {
        id = azurerm_virtual_network.vnet["vnet"].id
      }
    }
  })
  tags = var.tags
}


resource "azapi_resource" "virtualNetworkPeerings" {
  for_each = local.networking.vnet_peerings

  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01"
  name      = "${var.global_settings.name}-${each.value.name}"
  parent_id = can(each.value.from.id) ? each.value.from.id : azurerm_virtual_network.vnet[each.value.from.vnet_key].id

  body = jsonencode({
    properties = {
      allowForwardedTraffic     = lookup(each.value, "allow_forwarded_traffic", false)
      allowGatewayTransit       = lookup(each.value, "allow_gateway_transit", false)
      allowVirtualNetworkAccess = lookup(each.value, "allow_virtual_network_access", true)
      doNotVerifyRemoteGateways = lookup(each.value, "do_not_verify_remote_gateways", false)
      useRemoteGateways         = lookup(each.value, "use_remote_gateways", false)
      remoteVirtualNetwork = {
        id = can(each.value.to.remote_virtual_network_id) ? each.value.to.remote_virtual_network_id : azurerm_virtual_network.vnet[each.value.to.vnet_key].id
      }
    }
  })
}


module "diagnostic_log_analytics" {
  source   = "../../services/logmon/log_analytics"
  for_each = local.diagnostics.diagnostic_log_analytics

  global_settings     = var.global_settings
  log_analytics       = each.value
  location            = var.global_settings.location
  resource_group_name = azurerm_resource_group.rg[each.value.resource_group_key].name
  tags                = var.tags
}


module "diagnostic_log_analytics_diagnostics" {
  source   = "../../services/logmon/diagnostics"
  for_each = local.diagnostics.diagnostic_log_analytics

  resource_id = module.diagnostic_log_analytics[each.key].id
  diagnostics = local.combined_diagnostics
  profiles    = lookup(each.value, "diagnostic_profiles", {})
}


module "subscription_diagnostics" {
  source      = "../../services/logmon/diagnostics"
  resource_id = var.global_settings.client_config.subscription_id
  diagnostics = local.combined_diagnostics
  profiles = {
    subscription_diag = {
      definition_key   = "subscription_operations"
      destination_type = "log_analytics"
      destination_key  = "central_logs"
    }
  }
}


module "vnet_diagnostics" {
  source   = "../../services/logmon/diagnostics"
  for_each = local.networking.vnets

  resource_id = azurerm_virtual_network.vnet[each.key].id
  diagnostics = local.combined_diagnostics
  profiles    = each.value.diagnostic_profiles
}
