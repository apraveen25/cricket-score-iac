variable "resource_group_name" {
  description = "Resource group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "account_name" {
  description = "Globally-unique Cosmos DB account name (lowercase, 3-44 chars)."
  type        = string
}

variable "database_name" {
  description = "SQL database name."
  type        = string
}

variable "containers" {
  description = "SQL containers to create. Each entry needs a name and a partition key path."
  type = list(object({
    name               = string
    partition_key_path = string
  }))
}

variable "throughput" {
  description = "Database-level shared throughput in RU/s. 400 is the Azure minimum for manual throughput."
  type        = number
  default     = 400
  validation {
    condition     = var.throughput >= 400
    error_message = "Cosmos throughput must be at least 400 RU/s."
  }
}

variable "private_endpoint_subnet_id" {
  description = "Subnet in which to place the Cosmos DB private endpoint."
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for `privatelink.documents.azure.com`."
  type        = string
}

variable "rbac_principal_ids" {
  description = "Principal IDs (object IDs) to grant the Cosmos DB Built-in Data Contributor role."
  type        = list(string)
  default     = []
}

variable "log_analytics_workspace_id" {
  description = "Workspace ID for diagnostic settings."
  type        = string
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
