###############################################################################
# outputs.tf
# Root-level outputs — the minimum set needed to wire up pipelines and verify
# the deployment. Sensitive values (keys, connection strings) are marked so
# they're redacted from CLI output.
###############################################################################

output "resource_group_name" {
  description = "Name of the created resource group."
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Azure region used for the deployment."
  value       = azurerm_resource_group.this.location
}

output "frontend_url" {
  description = "Public URL of the Static Web App (the React/Next.js frontend)."
  value       = module.static_web_app.default_host_name
}

output "backend_private_hostname" {
  description = "Private DNS hostname of the backend App Service (resolvable from inside the VNET)."
  value       = module.app_service.default_hostname
}

output "cosmos_endpoint" {
  description = "Cosmos DB account endpoint (accessible only via Private Endpoint)."
  value       = module.cosmosdb.endpoint
}

output "servicebus_namespace" {
  description = "Fully-qualified Service Bus namespace."
  value       = module.servicebus.fully_qualified_namespace
}

output "key_vault_uri" {
  description = "Key Vault URI — used by the API to resolve Key Vault references in app settings."
  value       = module.security.key_vault_uri
}

output "api_identity_client_id" {
  description = "Client ID of the user-assigned identity used by the backend API (for Azure AD / RBAC)."
  value       = module.security.api_identity_client_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID — useful when configuring downstream diagnostic settings."
  value       = module.observability.log_analytics_workspace_id
}
