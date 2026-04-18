output "id" {
  description = "Resource ID of the Static Web App."
  value       = azurerm_static_web_app.this.id
}

output "default_host_name" {
  description = "Public hostname of the Static Web App."
  value       = azurerm_static_web_app.this.default_host_name
}

output "api_key" {
  description = "Deployment API key used by the SWA GitHub / Azure DevOps integration."
  value       = azurerm_static_web_app.this.api_key
  sensitive   = true
}
