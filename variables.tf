variable "global_settings" {
  default = {}
}

variable "location" {
  description = "The location of the resource group"
  type        = string
}

variable "environment" {
  description = "The release stage of the environment"
  default     = "dev"
  type        = string
}

variable "tags" {
  description = "Tags that should be applied to all deployed resources"
  type        = map(string)
}

variable "prefix" {
  default = null
  type    = string
}

variable "connectivity_hub_virtual_network_id" {
  description = "Virtual network resource id of the regional hub connectivity virtual network."
  type        = string
  default     = null
}

variable "data_management_zone_virtual_network_id" {
  description = "Virtual network resource id of the data management zone's virtual network."
  type        = string
  default     = null
}

variable "vnet_address_cidr" {
  description = "Address space to use for the Data Landing Zone VNet"
  type        = string
}

variable "services_subnet_cidr" {
  type        = string
  description = "Address space to use for the Shared Services subnet within the Data Landing Zone VNet"
}

variable "private_endpoint_subnet_cidr" {
  type        = string
  description = "Address space to use for the Private Endpoint subnet within the Data Landing Zone VNet"
}

variable "shared_databricks_pub_subnet_cidr" {
  type        = string
  description = "Address space to use for the Power BI / Power Platform vnet data gateway subnet within the Data Landing Zone VNet"
}

variable "shared_databricks_pri_subnet_cidr" {
  type        = string
  description = "Address space to use for the Virtual Network Gateway subnet within the Data Landing Zone VNet"
}

variable "aml_training_subnet_cidr" {
  type        = string
  description = "Address space to use for the Azure Machine Learning training subnet."
}

variable "dns_zones_remote_subscription_id" {
  type        = string
  description = "The id of the subscription where remote Private DNS Zones are deployed."
  default     = null
}

variable "dns_zones_remote_resource_group" {
  type        = string
  description = "Name of the resource group in the remote subscriptions where remote Private DNS Zones are deployed."
  default     = null
}

variable "dns_zones_remote_zones" {
  type        = list(string)
  description = "List of Private DNS Zone names from the remote subscription that will be linked to the Data Landing Zone"
  default     = []
}

variable "use_existing_shared_runtime_compute" {
  type        = bool
  description = "Feature flag determines whether to use existing Self-Hosted Integration Runtime compute resources associated with a remote Data Factory instance."
  default     = true
}

variable "remote_data_factory_resource_id" {
  type        = string
  description = "Resource id of the Data Factory hosted in the external (management zone) subscription."
  default     = null
}

variable "remote_data_factory_self_hosted_runtime_resource_id" {
  type        = string
  description = "Resource id of the external self-hosted integration runtime with existing compute resources."
  default     = null
}

variable "create_shared_runtime_compute_in_landing_zone" {
  type        = bool
  description = "Feature flag determines whether to create new compute resources in the Data Landing Zone for use by the Azure Data Factory Self-Hosted Integration Runtimes."
  default     = false
}

variable "data_factory_self_hosted_runtime_authorization_script" {
  type        = string
  description = "URI to PowerShell script responsible for associating compute resources with an Azure Data Factory Self-Hosted Integration Runtime."
  default     = "https://raw.githubusercontent.com/Azure/data-landing-zone/main/code/installSHIRGateway.ps1"
}

variable "vmss_vm_sku" {
  type        = string
  description = "The Virtual Machine Scale Set SKU to use when creating the compute resources for the Azure Data Factory Self-Hosted Integration Runtime."
  default     = "Standard_D4d_v4"
}

variable "vmss_instance_count" {
  type        = number
  description = "The number of VMSS compute instances."
  default     = 2
}

variable "remote_log_analytics_workspace_resource_id" {
  type        = string
  description = "The resource_id of the remotely hosted Log Analytics Workspace where diagnostic logs should be sent."
  default     = null
}

variable "remote_log_analytics_workspace_workspace_id" {
  type        = string
  description = "The workspace_id of the remotely hosted Log Analytics Workspace where diagnostic logs should be sent."
  default     = null
}

variable "metadata_sql_admin_password" {
  type        = string
  description = "The password which will be assigned to Azure SQL Database administrative user.  Leave this null to auto-generate a password and store it in Key Vault."
  default     = null
}

variable "adls_account_tier" {
  type        = string
  description = "Storage account tier option for the data lake storage accounts"
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.adls_account_tier)
    error_message = "Invalid input, options: \"Standard\", \"Premium\"."
  }
}

variable "adls_account_replication_type" {
  type        = string
  description = "Storage replication option for the data lake storage accounts"
  default     = "ZRS"

  validation {
    condition     = contains(["LRS", "ZRS"], var.adls_account_replication_type)
    error_message = "Invalid input, options: \"LRS\", \"ZRS\"."
  }
}

variable "deploy_shared_synapse_workspace" {
  type        = bool
  description = "Feature flag which determines if a shared Synapse Analytics Workspace will be deployed."
  default     = true
}

variable "deploy_shared_synapse_sql_pool" {
  type        = bool
  description = "Feature flag which determines if a shared Synapse Analytics sql pool will be deployed."
  default     = true
}

variable "deploy_shared_synapse_spark_pool" {
  type        = bool
  description = "Feature flag which determines if a shared Synapse Analytics spark pool will be deployed."
  default     = true
}

variable "synapse_sql_pool_sku" {
  type        = string
  description = "The SKU for the Synapse dedicated SQL Pool, if deployed."
  default     = "DW500c"
  validation {
    condition     = can(regex("DW100c|DW200c|DW300c|DW400c|DW500c|DW1000c|DW1500c|DW2000c|DW2500c|DW3000c|DW5000c|DW6000c|DW7500c|DW10000c|DW15000c|DW30000c", var.synapse_sql_pool_sku))
    error_message = "Err: Valid options are 'DW100c', 'DW200c', 'DW300c', 'DW400c', 'DW500c', 'DW1000c', 'DW1500c', 'DW2000c', 'DW2500c', 'DW3000c', 'DW5000c', 'DW6000c', 'DW7500c', 'DW10000c', 'DW15000c', 'DW30000c'."
  }
}
variable "synapse_spark_node_size" {
  type        = string
  description = "The size of the virtual machines used within the Spark pool."
  default     = "Small"

  validation {
    condition     = can(regex("Small|Medium|Large|XLarge|XXLarge", var.synapse_spark_node_size))
    error_message = "Err: Valid options are 'Small', 'Medium', 'Large', 'XLarge', 'XXLarge'."
  }
}
variable "synapse_spark_min_node_count" {
  type        = number
  description = "The minimum number of Spark nodes to deploy when using Autoscale.  Minimum is 3."
  default     = 3
}
variable "synapse_spark_max_node_count" {
  type        = number
  description = "The maximum number of Spark nodes to deploy when using Autoscale.  Maximum is 200."
  default     = 5
}
variable "deploy_shared_databricks_workspace" {
  type        = bool
  description = "Feature flag which determines if a shared Databricks Workspace will be deployed."
  default     = true
}

variable "databricks_ws_sku" {
  type        = string
  description = "(Optional) The SKU to use for the databricks instance"
  default     = "standard"
  validation {
    condition     = can(regex("standard|premium|trial", var.databricks_ws_sku))
    error_message = "Err: Valid options are 'standard', 'premium' or 'trial'."
  }
}
