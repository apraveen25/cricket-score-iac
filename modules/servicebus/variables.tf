variable "resource_group_name" {
  description = "Resource group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "namespace_name" {
  description = "Globally-unique Service Bus namespace name."
  type        = string
}

variable "sku" {
  description = "Namespace tier. Basic (queue only, no topics, no PE), Standard (topics, no PE), Premium (PE support, MI, isolation)."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard, or Premium."
  }
}

variable "queue_name" {
  description = "Primary queue."
  type        = string
}

variable "max_delivery_count" {
  description = "Max delivery attempts before a message is dead-lettered."
  type        = number
  default     = 10
}

variable "private_endpoint_subnet_id" {
  description = "Subnet for the namespace's private endpoint. Ignored unless sku == Premium."
  type        = string
  default     = null
}

variable "private_dns_zone_id" {
  description = "Private DNS zone for `privatelink.servicebus.windows.net`. Ignored unless sku == Premium."
  type        = string
  default     = null
}

variable "rbac_principal_ids" {
  description = "Principal IDs granted `Azure Service Bus Data Owner` on the namespace."
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Workspace for diagnostic settings."
  type        = string
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
