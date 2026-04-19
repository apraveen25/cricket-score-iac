###############################################################################
# modules/app_service/main.tf
#
# Why App Service (and not Azure Functions)?
#
#   This is a synchronous .NET Web API (the frontend calls it), that also
#   produces + consumes Service Bus messages as a background worker. App
#   Service gives us:
#     - Predictable cost on a small B1 plan (vs. Consumption plan cold starts)
#     - Straightforward support for long-running ASP.NET Core hosted services
#     - Simple VNET integration + private endpoint story
#   Azure Functions would be a better choice if the workload were purely
#   event-driven + bursty (e.g. queue-triggered-only). Swap this module for a
#   Function App later if that pattern evolves.
###############################################################################

resource "azurerm_service_plan" "this" {
  name                = var.plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = var.app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id

  https_only = true

  # Once the private endpoint is live, public access can be disabled outright.
  # This keeps the API strictly private while still letting Azure operate it.
  public_network_access_enabled = false

  # Route all outbound traffic through the VNET so calls to Cosmos / SB go
  # via the private endpoints, not the public internet.
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  site_config {
    always_on        = true
    ftps_state       = "Disabled"
    http2_enabled    = true
    minimum_tls_version = "1.2"

    # Force all outbound requests through the VNET (even DNS). Combined with
    # private DNS zones, this keeps all PaaS traffic on Microsoft's backbone.
    vnet_route_all_enabled = true

    application_stack {
      dotnet_version = var.dotnet_version
    }

    dynamic "cors" {
      for_each = length(var.allowed_cors_origins) > 0 ? [1] : []
      content {
        allowed_origins     = var.allowed_cors_origins
        support_credentials = false
      }
    }
  }

  app_settings = merge(
    {
      # When an App has *multiple* UAMIs, ASP.NET needs to know which one to
      # use for DefaultAzureCredential — set this to the UAMI's client ID.
      "AZURE_CLIENT_ID" = ""
    },
    var.app_settings
  )

  logs {
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
    application_logs {
      file_system_level = "Information"
    }
    detailed_error_messages = true
    failed_request_tracing  = true
  }

  tags = var.tags
}

###############################################################################
# Private Endpoint for inbound — the Static Web App calls this via the SWA
# "Bring Your Own API" feature or a front-door you add later.
###############################################################################
resource "azurerm_private_endpoint" "this" {
  name                = "pe-${var.app_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.app_name}"
    private_connection_resource_id = azurerm_linux_web_app.this.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "app-dns-zg"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

###############################################################################
# Diagnostics → Log Analytics
###############################################################################
resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diag-${var.app_name}"
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }
  enabled_log {
    category = "AppServiceConsoleLogs"
  }
  enabled_log {
    category = "AppServiceAppLogs"
  }
  enabled_log {
    category = "AppServiceAuditLogs"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
