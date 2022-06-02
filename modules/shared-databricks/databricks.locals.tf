locals {

  nsg_associations = {
    databricks_pub = {
      subnet_id = var.combined_objects_core.virtual_subnets["databricks_pub"].id
      nsg_id    = var.combined_objects_core.network_security_groups["databricks_pub"].id
    }
    databricks_pri = {
      subnet_id = var.combined_objects_core.virtual_subnets["databricks_pri"].id
      nsg_id    = var.combined_objects_core.network_security_groups["databricks_pri"].id
    }
  }

  databricks_workspaces = {
    shared_ws = {

      name                                  = "shared-databricks-lz01"
      location                              = var.global_settings.location
      resource_group_key                    = "databricks"
      sku                                   = var.module_settings.databricks_ws_sku
      public_network_access_enabled         = true
      network_security_group_rules_required = "AllRules"

      custom_parameters = {
        no_public_ip       = true
        public_subnet_key  = "databricks_pub"
        private_subnet_key = "databricks_pri"
        vnet_key           = "vnet"
      }
    }
  }

}


