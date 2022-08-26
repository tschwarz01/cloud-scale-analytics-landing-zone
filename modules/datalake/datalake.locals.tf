locals {

  storage_accounts = {
    raw = {
      name                     = "raw"
      resource_group_key       = "adls"
      location                 = var.global_settings.location
      account_tier             = var.module_settings.adls_account_tier
      account_replication_type = var.module_settings.adls_account_replication_type
    }
    curated = {
      name                     = "curated"
      resource_group_key       = "adls"
      location                 = var.global_settings.location
      account_tier             = var.module_settings.adls_account_tier
      account_replication_type = var.module_settings.adls_account_replication_type
    }
    workspace = {
      name                     = "workspace"
      resource_group_key       = "adls"
      location                 = var.global_settings.location
      account_tier             = var.module_settings.adls_account_tier
      account_replication_type = var.module_settings.adls_account_replication_type
    }
  }

  filesystems = {
    shared_synapse = {
      name        = "sharedsynapse"
      storage_key = "workspace"
    }
    sandbox = {
      name        = "sandbox"
      storage_key = "workspace"
    }
    landing = {
      name        = "landing"
      storage_key = "raw"
    }
    conformance = {
      name        = "conformance"
      storage_key = "raw"
    }
    enriched = {
      name        = "standardized"
      storage_key = "curated"
    }
    curated = {
      name        = "dataproducts"
      storage_key = "curated"
    }
  }

  private_endpoints = {
    raw_blob = {
      storage_key        = "raw"
      name               = "raw_blob"
      resource_group_key = "adls"
      location           = var.global_settings.location
      subnet_key         = "private_endpoints"
      private_service_connection = {
        name                 = "raw_blob"
        is_manual_connection = false
        subresource_names    = ["blob"]
      }
      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.blob.core.windows.net"]
      }
    }
    raw_dfs = {
      storage_key        = "raw"
      name               = "raw_dfs"
      resource_group_key = "adls"
      location           = var.global_settings.location
      subnet_key         = "private_endpoints"
      private_service_connection = {
        name                 = "raw_dfs"
        is_manual_connection = false
        subresource_names    = ["dfs"]
      }
      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.dfs.core.windows.net"]
      }
    }
    curated_blob = {
      storage_key        = "curated"
      name               = "curate_blob"
      resource_group_key = "adls"
      location           = var.global_settings.location
      subnet_key         = "private_endpoints"
      private_service_connection = {
        name                 = "curated_blob"
        is_manual_connection = false
        subresource_names    = ["blob"]
      }
      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.blob.core.windows.net"]
      }
    }
    curated_dfs = {
      storage_key        = "curated"
      name               = "curated_dfs"
      resource_group_key = "adls"
      location           = var.global_settings.location
      subnet_key         = "private_endpoints"
      private_service_connection = {
        name                 = "curated_dfs"
        is_manual_connection = false
        subresource_names    = ["dfs"]
      }
      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.dfs.core.windows.net"]
      }
    }
    workspace_blob = {
      storage_key        = "workspace"
      name               = "workspace_blob"
      resource_group_key = "adls"
      location           = var.global_settings.location
      subnet_key         = "private_endpoints"
      private_service_connection = {
        name                 = "workspace_blob"
        is_manual_connection = false
        subresource_names    = ["blob"]
      }
      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.blob.core.windows.net"]
      }
    }
    workspace_dfs = {
      storage_key        = "workspace"
      name               = "workspace_dfs"
      resource_group_key = "adls"
      location           = var.global_settings.location
      subnet_key         = "private_endpoints"
      private_service_connection = {
        name                 = "workspace_dfs"
        is_manual_connection = false
        subresource_names    = ["dfs"]
      }
      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.dfs.core.windows.net"]
      }
    }

  }


}
