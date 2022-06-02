locals {

  storage_accounts = {
    external_upload = {
      name               = "externaldata"
      resource_group_key = "upload_ingestion"
      location           = var.global_settings.location
    }
  }

  containers = {
    publisher1 = {
      name        = "externalpublisher01"
      storage_key = "external_upload"
    }
    publisher2 = {
      name        = "externalpublisher02"
      storage_key = "external_upload"
    }
  }

  private_endpoints = {
    raw_blob = {
      storage_key        = "external_upload"
      name               = "externaldatalanding"
      resource_group_key = "upload_ingestion"
      location           = var.global_settings.location
      subnet_key         = "private_endpoints"
      private_service_connection = {
        name                 = "ext_blob"
        is_manual_connection = false
        subresource_names    = ["blob"]
      }
      private_dns = {
        zone_group_name = "default"
        keys            = ["privatelink.blob.core.windows.net"]
      }
    }
  }
}
