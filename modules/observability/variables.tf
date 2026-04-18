variable "resource_group_name" {
  description = "Resource group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "law_name" {
  description = "Log Analytics Workspace name."
  type        = string
}

variable "appi_name" {
  description = "Application Insights component name."
  type        = string
}

variable "retention_days" {
  description = "Log Analytics retention in days. 30 is the minimum billable floor and the cheapest option."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
