###############################################################################
# modules/cosmosdb/main.tf
#
# Azure Cosmos DB (SQL / Core API)
#
# Cost-optimisation choices:
#   - Single region, Session consistency (cheapest non-eventual option)
#   - Shared database-level throughput (400 RU/s minimum)
#   - Public network access disabled; traffic only through Private Endpoint
#
# Security choices:
#   - Local auth (keys) disabled → clients MUST use Azure AD / Managed Identity
#   - Data-plane RBAC role assigned to each principal in rbac_principal_ids
###############################################################################

resource "azurerm_cosmosdb_account" "this" {
  name                = var.account_name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  # Lock down public traffic; the private endpoint is the only ingress.
  public_network_access_enabled = false

  # Force AAD-based auth. This catches accidental use of account keys.
  local_authentication_disabled = true

  automatic_failover_enabled = false
  free_tier_enabled          = false # one free tier per subscription — opt in manually

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  # Minimal backup — free built-in 8h periodic backups.
  backup {
    type                = "Periodic"
    interval_in_minutes = 240
    retention_in_hours  = 8
    storage_redundancy  = "Local"
  }

  tags = var.tags
}

###############################################################################
# SQL database + container (shared throughput)
###############################################################################
resource "azurerm_cosmosdb_sql_database" "this" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = var.throughput
}

resource "azurerm_cosmosdb_sql_container" "this" {
  name                  = var.container_name
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = azurerm_cosmosdb_sql_database.this.name
  partition_key_paths   = [var.partition_key_path]
  partition_key_version = 2
}

###############################################################################
# Data-plane RBAC
#
# `00000000-0000-0000-0000-000000000002` is the built-in
# "Cosmos DB Built-in Data Contributor" role definition ID. This is the
# correct way to grant read/write access when local auth is disabled.
###############################################################################
resource "azurerm_cosmosdb_sql_role_assignment" "data_contributor" {
  for_each = { for i, v in var.rbac_principal_ids : tostring(i) => v }

  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  role_definition_id  = "${azurerm_cosmosdb_account.this.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = each.value
  scope               = azurerm_cosmosdb_account.this.id
}

###############################################################################
# Private Endpoint
###############################################################################
resource "azurerm_private_endpoint" "this" {
  name                = "pe-${var.account_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.account_name}"
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    is_manual_connection           = false
    subresource_names              = ["Sql"]
  }

  private_dns_zone_group {
    name                 = "cosmos-dns-zg"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

###############################################################################
# Diagnostics → Log Analytics
###############################################################################
resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "diag-${var.account_name}"
  target_resource_id         = azurerm_cosmosdb_account.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "DataPlaneRequests"
  }
  enabled_log {
    category = "ControlPlaneRequests"
  }
  metric {
    category = "Requests"
    enabled  = true
  }
}
