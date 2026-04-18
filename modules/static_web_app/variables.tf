variable "resource_group_name" {
  description = "Resource group."
  type        = string
}

variable "location" {
  description = "Azure region. SWA is only available in a subset of regions; the module falls back to `centralus` if the given region isn't supported."
  type        = string
}

variable "name" {
  description = "Static Web App name."
  type        = string
}

variable "sku" {
  description = "`Free` (dev/test) or `Standard` (custom domain SSL, private linking)."
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.sku)
    error_message = "sku must be Free or Standard."
  }
}

variable "app_settings" {
  description = "Application settings exposed to the SWA build / runtime."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
