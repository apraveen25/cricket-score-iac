###############################################################################
# locals.tf
# Centralised naming + tagging. Having one source of truth for the naming
# pattern means every resource name (and every tag) is guaranteed to follow the
# same convention.
#
# Naming convention:   <type>-<project>-<env>-<locshort>[-<suffix>]
# Example:             app-cricket-dev-cus
#
# Some Azure resources have stricter rules (no dashes, global uniqueness).
# Those exceptions are handled per-module.
###############################################################################

locals {
  # A short, deterministic random suffix for globally-unique names (storage,
  # key vault, cosmos, etc.). `random_string` is regenerated only if the
  # resource group name changes — see main.tf.
  name_prefix = "${var.project}-${var.environment}-${var.location_short}"

  common_tags = merge(
    {
      project     = var.project
      environment = var.environment
      managed_by  = "terraform"
      owner       = "platform-team"
      cost_center = "engineering"
    },
    var.tags
  )

  # Resource-specific names kept together so they're easy to audit.
  rg_name                = "rg-${local.name_prefix}"
  law_name               = "log-${local.name_prefix}"
  appi_name              = "appi-${local.name_prefix}"
  kv_name                = "kv-${local.name_prefix}"           # 3-24 chars, must be globally unique → suffix appended in module
  vnet_name              = "vnet-${local.name_prefix}"
  app_plan_name          = "asp-${local.name_prefix}"
  app_service_name       = "app-${local.name_prefix}"          # must be globally unique
  swa_name               = "swa-${local.name_prefix}"
  cosmos_account_name    = "cosmos-${local.name_prefix}"       # must be globally unique, lowercase
  servicebus_ns_name     = "sb-${local.name_prefix}"           # must be globally unique

  # Private DNS zones are standard (provider-published) names.
  private_dns_zones = {
    cosmos     = "privatelink.documents.azure.com"
    servicebus = "privatelink.servicebus.windows.net"
    appservice = "privatelink.azurewebsites.net"
    keyvault   = "privatelink.vaultcore.azure.net"
  }
}
