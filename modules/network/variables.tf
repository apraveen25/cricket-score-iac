variable "resource_group_name" {
  description = "Resource group for all networking resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "vnet_name" {
  description = "Name of the VNET."
  type        = string
}

variable "address_space" {
  description = "Address space for the VNET."
  type        = list(string)
}

variable "subnets" {
  description = "Subnets keyed by purpose (app, data, integration)."
  type = map(object({
    address_prefixes        = list(string)
    delegate_to_app_service = optional(bool, false)
    service_endpoints       = optional(list(string), [])
  }))
}

variable "private_dns_zones" {
  description = "Map of logical name -> DNS zone FQDN. These zones will be created and linked to the VNET."
  type        = map(string)
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
