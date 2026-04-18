###############################################################################
# main.tf
# Root module that wires the feature modules together.
#
# Module graph:
#
#   network ──► observability ──► security ──► cosmosdb
#                                         └──► servicebus
#                                         └──► app_service ──► static_web_app
#
# Each module is intentionally small and owns its own variables / outputs.
###############################################################################

# Deterministic short suffix for resources that need global uniqueness.
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
  numeric = true

  # Regenerate only when the project/env changes, not on every apply.
  keepers = {
    project     = var.project
    environment = var.environment
    location    = var.location
  }
}

resource "azurerm_resource_group" "this" {
  name     = local.rg_name
  location = var.location
  tags     = local.common_tags
}

###############################################################################
# Observability — created early so later modules can plug diagnostics in.
###############################################################################
module "observability" {
  source = "./modules/observability"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  law_name            = local.law_name
  appi_name           = local.appi_name
  tags                = local.common_tags
}

###############################################################################
# Networking — VNET + subnets + private DNS zones.
###############################################################################
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  vnet_name           = local.vnet_name
  address_space       = var.vnet_address_space
  subnets             = var.subnets
  private_dns_zones   = local.private_dns_zones
  tags                = local.common_tags
}

###############################################################################
# Security — Key Vault + user-assigned identity for the API.
###############################################################################
module "security" {
  source = "./modules/security"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  key_vault_name      = "${local.kv_name}-${random_string.suffix.result}"
  identity_name       = "id-api-${local.name_prefix}"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.common_tags
}

###############################################################################
# Cosmos DB — locked down behind a Private Endpoint in the data subnet.
###############################################################################
module "cosmosdb" {
  source = "./modules/cosmosdb"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  account_name        = "${local.cosmos_account_name}-${random_string.suffix.result}"
  database_name       = var.cosmos_database_name
  container_name      = var.cosmos_container_name
  partition_key_path  = var.cosmos_partition_key_path
  throughput          = var.cosmos_throughput

  private_endpoint_subnet_id = module.network.subnet_ids["data"]
  private_dns_zone_id        = module.network.private_dns_zone_ids["cosmos"]

  # Grant the API's managed identity data-plane access.
  rbac_principal_ids = [module.security.api_identity_principal_id]

  log_analytics_workspace_id = module.observability.log_analytics_workspace_id
  tags                       = local.common_tags
}

###############################################################################
# Service Bus — queue + dead-letter, private-link where SKU supports it.
###############################################################################
module "servicebus" {
  source = "./modules/servicebus"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  namespace_name      = "${local.servicebus_ns_name}-${random_string.suffix.result}"
  sku                 = var.servicebus_sku
  queue_name          = var.servicebus_queue_name
  max_delivery_count  = var.servicebus_max_delivery_count

  # Private endpoints only work on Premium. The module handles this conditional.
  private_endpoint_subnet_id = module.network.subnet_ids["integration"]
  private_dns_zone_id        = module.network.private_dns_zone_ids["servicebus"]

  # Grant the API's managed identity sender + receiver roles.
  rbac_principal_ids = [module.security.api_identity_principal_id]

  log_analytics_workspace_id = module.observability.log_analytics_workspace_id
  tags                       = local.common_tags
}

###############################################################################
# Backend API — .NET App Service, VNET-integrated, managed identity.
###############################################################################
module "app_service" {
  source = "./modules/app_service"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  plan_name           = local.app_plan_name
  app_name            = "${local.app_service_name}-${random_string.suffix.result}"
  sku_name            = var.app_service_sku
  dotnet_version      = var.dotnet_version

  # VNET integration (outbound) — into the app subnet.
  vnet_integration_subnet_id = module.network.subnet_ids["app"]

  # Private endpoint for inbound traffic from the VNET only.
  private_endpoint_subnet_id = module.network.subnet_ids["app"]
  private_dns_zone_id        = module.network.private_dns_zone_ids["appservice"]

  # Use the pre-created user-assigned identity so the API can access Cosmos / SB.
  user_assigned_identity_id = module.security.api_identity_id

  # App settings wire the API to its dependencies. Secrets go via Key Vault refs
  # where possible; endpoints are fine as plain settings.
  app_settings = {
    "ASPNETCORE_ENVIRONMENT"                = var.environment
    "CosmosDb__Endpoint"                    = module.cosmosdb.endpoint
    "CosmosDb__DatabaseName"                = var.cosmos_database_name
    "CosmosDb__ContainerName"               = var.cosmos_container_name
    "ServiceBus__FullyQualifiedNamespace"   = module.servicebus.fully_qualified_namespace
    "ServiceBus__QueueName"                 = var.servicebus_queue_name
    "AzureAd__ManagedIdentityClientId"      = module.security.api_identity_client_id
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = module.observability.appinsights_connection_string
  }

  allowed_cors_origins       = var.allowed_cors_origins
  log_analytics_workspace_id = module.observability.log_analytics_workspace_id
  tags                       = local.common_tags
}

###############################################################################
# Frontend — Static Web App.
###############################################################################
module "static_web_app" {
  source = "./modules/static_web_app"

  resource_group_name = azurerm_resource_group.this.name
  # SWAs are limited to a specific set of regions; centralus is always valid
  # and is the documented default when the project's region isn't supported.
  # The module reconciles `location` against the allow-list.
  location = azurerm_resource_group.this.location
  name     = "${local.swa_name}-${random_string.suffix.result}"
  sku      = var.static_web_app_sku

  # Wire the frontend to the backend URL as an app setting — the frontend can
  # read it at build time or runtime depending on the framework.
  app_settings = {
    "API_BASE_URL" = "https://${module.app_service.default_hostname}"
  }

  tags = local.common_tags
}

# Convenience data source used for Key Vault's access policy.
data "azurerm_client_config" "current" {}
