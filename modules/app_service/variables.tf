variable "resource_group_name" {
  description = "Resource group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "plan_name" {
  description = "App Service Plan name."
  type        = string
}

variable "app_name" {
  description = "Globally-unique App Service (Linux Web App) name."
  type        = string
}

variable "sku_name" {
  description = "Plan SKU. B1 is the smallest that supports VNET integration + private endpoints."
  type        = string
  default     = "B1"
}

variable "dotnet_version" {
  description = ".NET runtime version."
  type        = string
  default     = "8.0"
}

variable "vnet_integration_subnet_id" {
  description = "Delegated subnet used for outbound VNET integration (must be delegated to Microsoft.Web/serverFarms)."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet for the inbound private endpoint."
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone for `privatelink.azurewebsites.net`."
  type        = string
}

variable "user_assigned_identity_id" {
  description = "Resource ID of the user-assigned managed identity attached to the App."
  type        = string
}

variable "app_settings" {
  description = "Additional app settings (merged with defaults)."
  type        = map(string)
  default     = {}
}

variable "allowed_cors_origins" {
  description = "Origins allowed to call the API (typically the SWA hostname)."
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
