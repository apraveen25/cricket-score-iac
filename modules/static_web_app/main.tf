###############################################################################
# modules/static_web_app/main.tf
#
# Static Web App for the React / Next.js frontend.
#
# Regional availability is narrower than most services. If the caller's region
# is not on the allow-list we silently fall back to `centralus` (always
# available) — the actual *content* is served globally from Azure's edge.
###############################################################################

locals {
  supported_swa_regions = [
    "westus2", "centralus", "eastus2", "westeurope", "eastasia"
  ]
  effective_location = contains(local.supported_swa_regions, var.location) ? var.location : "centralus"
}

resource "azurerm_static_web_app" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = local.effective_location
  sku_tier            = var.sku
  sku_size            = var.sku

  app_settings = var.app_settings

  tags = var.tags
}
