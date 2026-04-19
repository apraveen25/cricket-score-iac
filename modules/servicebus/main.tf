###############################################################################
# modules/servicebus/main.tf
#
# Azure Service Bus
#
# Why a Queue (not a Topic)?
#   - The backend API is a single logical consumer of order messages; there is
#     no fan-out to multiple subscribers in this reference architecture.
#   - Queues are simpler (1:1), cheaper, and sufficient for the producer/
#     consumer pattern described. Promote to Topic later if you need pub/sub.
#
# Why Standard (by default)?
#   - Premium is required for Private Endpoints + true network isolation, but
#     it's ~10x more expensive. For a demo/test environment, Standard with
#     RBAC auth is a sensible balance. Premium is a flip of `servicebus_sku`.
#
# Reliability features:
#   - Dead-letter queue enabled for expired messages AND filter evaluation
#     failures.
#   - Lock duration tuned for short handlers; max_delivery_count controls retry.
###############################################################################

resource "azurerm_servicebus_namespace" "this" {
  name                = var.namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  # Disable public access only on Premium (not supported on lower SKUs).
  public_network_access_enabled = var.sku == "Premium" ? false : true

  # System-assigned identity lets the namespace emit logs with its own identity
  # if needed; the API talks to SB via its UAMI (granted below).
  identity {
    type = "SystemAssigned"
  }

  minimum_tls_version = "1.2"
  tags                = var.tags
}

###############################################################################
# Queue + dead-letter
###############################################################################
resource "azurerm_servicebus_queue" "this" {
  name         = var.queue_name
  namespace_id = azurerm_servicebus_namespace.this.id

  # Reliability
  max_delivery_count                      = var.max_delivery_count
  dead_lettering_on_message_expiration    = true
  lock_duration                           = "PT1M"  # 1 minute
  default_message_ttl                     = "P14D"  # 14 days
  max_size_in_megabytes                   = 1024
  requires_duplicate_detection            = false
  duplicate_detection_history_time_window = "PT10M"

  # Partitioning is unavailable on Premium in newer namespaces — keep off.
  partitioning_enabled = false
}

###############################################################################
# RBAC — `Azure Service Bus Data Owner` covers send + receive + manage on the
# namespace. Scoping down to the queue would work too; keeping at namespace
# level is simpler for a single-queue setup.
###############################################################################
resource "azurerm_role_assignment" "sb_data_owner" {
  for_each = { for i, v in var.rbac_principal_ids : tostring(i) => v }

  scope                = azurerm_servicebus_namespace.this.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = each.value
}

###############################################################################
# Private Endpoint — only on Premium
###############################################################################
resource "azurerm_private_endpoint" "this" {
  count = var.sku == "Premium" && var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-${var.namespace_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.namespace_name}"
    private_connection_resource_id = azurerm_servicebus_namespace.this.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []
    content {
      name                 = "sb-dns-zg"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}

###############################################################################
# Diagnostics
###############################################################################
resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diag-${var.namespace_name}"
  target_resource_id         = azurerm_servicebus_namespace.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "OperationalLogs"
  }
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
