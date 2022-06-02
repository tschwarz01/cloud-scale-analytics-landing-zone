variable "location" {
  description = "The supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group. Changing this forces a new resource to be created."
  type        = string
}

variable "resource_id" {
  description = "The ID of the Private Link Enabled Remote Resource which this Private Endpoint should be connected to."
  type        = string
}

variable "name" {
  description = "(Required) Specifies the name. Changing this forces a new resource to be created."
  type        = string
}

variable "private_service_connection" {
  description = "A private_service_connection block"

}

variable "private_dns_zones" {
  description = "Private DNS Zones object containing details about all zones deployed by this template."
}

variable "subnet_id" {
  description = "The ID of the Subnet from which Private IP Addresses will be allocated for this Private Endpoint."
  type        = string
}

variable "private_dns" {
  description = "A private_dns_zone_group block"
  type = object({
    zone_group_name = string
    keys            = list(string)
  })
}

variable "tags" {
  default = {}
}
