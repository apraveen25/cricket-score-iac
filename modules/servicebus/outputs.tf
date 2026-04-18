output "namespace_id" {
  description = "Resource ID of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.this.id
}

output "namespace_name" {
  description = "Service Bus namespace name."
  value       = azurerm_servicebus_namespace.this.name
}

output "fully_qualified_namespace" {
  description = "Fully-qualified namespace (e.g. sb-app-dev-cus-1234.servicebus.windows.net) — used with DefaultAzureCredential."
  value       = "${azurerm_servicebus_namespace.this.name}.servicebus.windows.net"
}

output "queue_name" {
  description = "Primary queue name."
  value       = azurerm_servicebus_queue.this.name
}
