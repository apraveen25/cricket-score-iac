output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.this.name
}

output "appinsights_id" {
  description = "Resource ID of the Application Insights component."
  value       = azurerm_application_insights.this.id
}

output "appinsights_instrumentation_key" {
  description = "Application Insights instrumentation key (legacy)."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "appinsights_connection_string" {
  description = "Application Insights connection string — the modern way to wire SDKs."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}
