###############################################################################
# modules/observability/main.tf
#
# A single Log Analytics Workspace + a workspace-based Application Insights
# component. Both PaaS and app-level telemetry funnel into the same workspace,
# which is the modern (post-2024) recommended topology for Azure Monitor.
###############################################################################

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.law_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_days
  tags                = var.tags
}

resource "azurerm_application_insights" "this" {
  name                = var.appi_name
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = var.tags
}
