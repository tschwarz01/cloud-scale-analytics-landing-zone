#########################################
##          General Settings
#########################################
location    = "southcentralus"
environment = "dev"
tags = {
  Org = "Cloud Ops"
}


#########################################
##        Core Network Settings
#########################################
vnet_address_cidr                       = "10.111.0.0/21"
services_subnet_cidr                    = "10.111.0.0/24"
private_endpoint_subnet_cidr            = "10.111.1.0/24"
shared_databricks_pub_subnet_cidr       = "10.111.2.0/25"
shared_databricks_pri_subnet_cidr       = "10.111.2.128/25"
connectivity_hub_virtual_network_id     = "/subscriptions/893395a4-65a3-4525-99ea-2378c6e0dbed/resourceGroups/rg-network_connectivity_hub/providers/Microsoft.Network/virtualNetworks/vnet-connectivity_hub"
data_management_zone_virtual_network_id = "/subscriptions/47f7e6d7-0e52-4394-92cb-5f106bbc647f/resourceGroups/tpaa-dev-network/providers/Microsoft.Network/virtualNetworks/tpaa-dev-caf-csa-mz-vnet"


#########################################
##    Private DNS Zone Settings - 
##  Remote Subscription Hosted Zones
#########################################
remote_private_dns_zones = {
  vnet = {

    create_vnet_links_to_remote_zones = true
    vnet_key                          = "vnet"
    subscription_id                   = "c00669a2-37e9-4e0d-8b57-4e8dd0fcdd4a"
    resource_group_name               = "rg-scus-pe-lab-network"

    private_dns_zones = [
      "privatelink.blob.core.windows.net",
      "privatelink.dfs.core.windows.net",
      "privatelink.queue.core.windows.net",
      "privatelink.vaultcore.azure.net",
      "privatelink.datafactory.azure.net",
      "privatelink.adf.azure.com",
      "privatelink.purview.azure.com",
      "privatelink.purviewstudio.azure.com",
      "privatelink.servicebus.windows.net",
      "privatelink.azurecr.io",
      "privatelink.azuresynapse.net",
      "privatelink.sql.azuresynapse.net",
      "privatelink.dev.azuresynapse.net",
      "privatelink.database.windows.net",
      "privatelink.search.windows.net",
      "privatelink.cognitiveservices.azure.com",
      "privatelink.api.azureml.ms",
      "privatelink.file.core.windows.net",
      "privatelink.notebooks.azure.net"
    ]

  }
}


#########################################
##   Shared Integration Module Settings
#########################################
use_existing_shared_runtime_compute = true

# Resource id of the Data Factory hosted in the external (management zone) subscription.
remote_data_factory_resource_id = "/subscriptions/47f7e6d7-0e52-4394-92cb-5f106bbc647f/resourceGroups/tpaa-dev-integration/providers/Microsoft.DataFactory/factories/tpaa-dev-adf-integration21tws"

# Resource id of the external self-hosted integration runtime with existing compute resources.
remote_data_factory_self_hosted_runtime_resource_id = "/subscriptions/47f7e6d7-0e52-4394-92cb-5f106bbc647f/resourcegroups/tpaa-dev-integration/providers/Microsoft.DataFactory/factories/tpaa-dev-adf-integration21tws/integrationruntimes/tpaa-dev-adfsharedshir21"


create_shared_runtime_compute_in_landing_zone         = false
data_factory_self_hosted_runtime_authorization_script = "https://raw.githubusercontent.com/Azure/data-landing-zone/main/code/installSHIRGateway.ps1"
vmss_vm_sku                                           = "Standard_D4d_v4"
vmss_instance_count                                   = 2


#########################################
##      Diagnostics Settings
#########################################
remote_log_analytics_workspace_resource_id  = "/subscriptions/47f7e6d7-0e52-4394-92cb-5f106bbc647f/resourceGroups/tpaa-dev-logging-and-monitoring/providers/Microsoft.OperationalInsights/workspaces/tpaa-dev-logs"
remote_log_analytics_workspace_workspace_id = "f83cc9b8-e3d7-4af4-b3da-b5b3290f2bf9"


#########################################
##      Datalake Storage Settings
#########################################
adls_account_tier             = "Premium"
adls_account_replication_type = "LRS"


#########################################
##      Shared Synapse Settings
#########################################
deploy_shared_synapse_workspace  = true
deploy_shared_synapse_sql_pool   = true
deploy_shared_synapse_spark_pool = true
synapse_sql_pool_sku             = "DW100c"
synapse_spark_min_node_count     = 3
synapse_spark_max_node_count     = 50

#########################################
##      Shared Databricks Settings
#########################################
deploy_shared_databricks_workspace = true
databricks_ws_sku                  = "standard"
