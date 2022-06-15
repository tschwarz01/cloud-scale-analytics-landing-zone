terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.7.0"
    }
  }

  backend "azurerm" {
    subscription_id      = "893395a4-65a3-4525-99ea-2378c6e0dbed"
    resource_group_name  = "rg-data-landing-zone-terraform"
    storage_account_name = "stgcafcsatfstate"
    container_name       = "caf-csa-landing-zone"
    key                  = "dlz.terraform.tfstate"
  }

  required_version = ">= 0.15"
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    template_deployment {
      delete_nested_items_during_deletion = true
    }
  }
}


data "azurerm_client_config" "default" {}
data "azuread_client_config" "current" {}
data "azurerm_subscription" "current" {}

data "terraform_remote_state" "dmlz" {
  backend = "azurerm"

  config = {
    subscription_id      = var.remote_state_subscription_id
    container_name       = var.remote_state_container_name
    resource_group_name  = var.remote_state_resource_group_name
    storage_account_name = var.remote_state_storage_account_name
    key                  = var.remote_state_tfstate_key
  }
}


module "core" {
  source = "./modules/core"

  global_settings = local.global_settings
  module_settings = local.core_module_settings
  tags            = local.global_settings.tags
}


module "databricks_monitoring" {
  source = "./modules/databricks-monitoring"

  global_settings       = local.global_settings
  module_settings       = local.dbmon_module_settings
  combined_objects_core = local.combined_objects_core
  tags                  = local.global_settings.tags
}


module "hive_metastore" {
  source = "./modules/hive"

  global_settings       = local.global_settings
  module_settings       = local.hive_module_settings
  combined_objects_core = local.combined_objects_core
  tags                  = local.global_settings.tags
}


module "datalake_services" {
  source = "./modules/datalake"

  global_settings       = local.global_settings
  module_settings       = local.datalake_module_settings
  combined_objects_core = local.combined_objects_core
  tags                  = local.global_settings.tags
}


module "external_data_upload" {
  source = "./modules/external-data"

  global_settings       = local.global_settings
  module_settings       = local.extdata_module_settings
  combined_objects_core = local.combined_objects_core
  tags                  = local.global_settings.tags
}


module "integration" {
  source = "./modules/integration"

  global_settings       = local.global_settings
  module_settings       = local.integration_module_settings
  combined_objects_core = local.combined_objects_core
  tags                  = local.global_settings.tags
}


module "ingestion_framework" {
  source = "./modules/ingestion-framework"

  global_settings                  = local.global_settings
  module_settings                  = local.ingestion_module_settings
  combined_objects_core            = local.combined_objects_core
  self_hosted_integration_runtimes = module.integration.self_hosted_integration_runtimes
  data_factories                   = module.integration.data_factories
  tags                             = local.global_settings.tags
}


module "shared_databricks" {
  for_each = { for k, v in local.module_flags : k => v if k == "databricks" && v.enabled == true }

  source                = "./modules/shared-databricks"
  global_settings       = local.global_settings
  module_settings       = local.databricks_module_settings
  combined_objects_core = local.combined_objects_core
  tags                  = local.global_settings.tags
}


module "shared_synapse" {
  for_each = { for k, v in local.module_flags : k => v if k == "synapse" && v.enabled == true }

  source                = "./modules/shared-synapse"
  global_settings       = local.global_settings
  module_settings       = local.synapse_module_settings
  combined_objects_core = local.combined_objects_core
  tags                  = local.global_settings.tags
}


output "combined_objects_core" {
  value = local.combined_objects_core
}

output "datalake_services" {
  value     = module.datalake_services
  sensitive = true
}

