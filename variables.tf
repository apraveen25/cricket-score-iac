###############################################################################
# variables.tf
# Input variables for the root module. Tfvars files under `environments/`
# supply per-environment values (dev / test / prod).
###############################################################################

variable "subscription_id" {
  description = "Target Azure subscription ID. Can also be sourced from ARM_SUBSCRIPTION_ID."
  type        = string
  default     = null
}

variable "project" {
  description = "Short project / product code used in resource naming (3-12 chars, lowercase letters & digits only)."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,12}$", var.project))
    error_message = "project must be 3-12 chars, lowercase letters and digits only."
  }
}

variable "environment" {
  description = "Deployment environment. One of dev, test, prod."
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of dev, test, prod."
  }
}

variable "location" {
  description = "Primary Azure region (e.g. centralus, eastus, westeurope)."
  type        = string
  default     = "centralus"
}

variable "location_short" {
  description = "Short code for the region used in resource names (e.g. 'cus' for Central US)."
  type        = string
  default     = "cus"
}

variable "tags" {
  description = "Additional tags merged into locals.common_tags."
  type        = map(string)
  default     = {}
}

###############################################################################
# Networking
###############################################################################

variable "vnet_address_space" {
  description = "Address space for the VNET."
  type        = list(string)
  default     = ["10.20.0.0/16"]
}

variable "subnets" {
  description = <<EOT
Subnet definitions keyed by purpose. Each value is an object with address_prefixes
and an optional `delegate_to_app_service` flag. The app subnet must be delegated
to `Microsoft.Web/serverFarms` so App Service VNET integration works.
EOT
  type = map(object({
    address_prefixes        = list(string)
    delegate_to_app_service = optional(bool, false)
    service_endpoints       = optional(list(string), [])
  }))
  default = {
    app = {
      address_prefixes        = ["10.20.1.0/24"]
      delegate_to_app_service = true
    }
    data = {
      address_prefixes = ["10.20.2.0/24"]
    }
    integration = {
      address_prefixes = ["10.20.3.0/24"]
    }
  }
}

###############################################################################
# Backend API (App Service)
###############################################################################

variable "app_service_sku" {
  description = "App Service plan SKU. B1 is the smallest tier that supports VNET integration + private endpoints."
  type        = string
  default     = "B1"
}

variable "dotnet_version" {
  description = ".NET version running in the App Service."
  type        = string
  default     = "8.0"
}

###############################################################################
# Cosmos DB
###############################################################################

variable "cosmos_throughput" {
  description = "Shared database-level throughput (RU/s). 400 is the minimum manual throughput."
  type        = number
  default     = 400
}

variable "cosmos_database_name" {
  description = "Cosmos SQL database name."
  type        = string
  default     = "appdb"
}

variable "cosmos_container_name" {
  description = "Cosmos SQL container name."
  type        = string
  default     = "items"
}

variable "cosmos_partition_key_path" {
  description = "Partition key path for the Cosmos container."
  type        = string
  default     = "/pk"
}

###############################################################################
# Service Bus
###############################################################################

variable "servicebus_sku" {
  description = "Service Bus namespace tier. Premium is required for private endpoints; Standard is used for cost-optimised non-prod."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.servicebus_sku)
    error_message = "servicebus_sku must be Basic, Standard, or Premium."
  }
}

variable "servicebus_queue_name" {
  description = "Primary queue name used by the backend API."
  type        = string
  default     = "orders"
}

variable "servicebus_max_delivery_count" {
  description = "Max delivery attempts before messages go to the dead-letter queue."
  type        = number
  default     = 10
}

###############################################################################
# Static Web App
###############################################################################

variable "static_web_app_sku" {
  description = "Static Web App SKU. `Free` is sufficient for dev/test; `Standard` is required for private linking."
  type        = string
  default     = "Free"
}

variable "frontend_custom_domain" {
  description = "Optional custom domain for the Static Web App. Leave null to skip."
  type        = string
  default     = null
}

###############################################################################
# CORS
###############################################################################

variable "allowed_cors_origins" {
  description = "Origins allowed to call the backend API. Typically the SWA default hostname."
  type        = list(string)
  default     = []
}
