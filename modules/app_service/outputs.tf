output "app_service_id" {
  description = "Resource ID of the App Service."
  value       = azurerm_linux_web_app.this.id
}

output "app_service_name" {
  description = "App Service name."
  value       = azurerm_linux_web_app.this.name
}

output "default_hostname" {
  description = "Default hostname of the App Service (resolves to a private IP when reached from the VNET)."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "service_plan_id" {
  description = "App Service Plan ID — useful if scaling knobs are added later."
  value       = azurerm_service_plan.this.id
}
