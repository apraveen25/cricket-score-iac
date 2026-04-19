output "account_id" {
  description = "Resource ID of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.this.id
}

output "endpoint" {
  description = "Cosmos DB endpoint URL."
  value       = azurerm_cosmosdb_account.this.endpoint
}

output "database_name" {
  description = "SQL database name."
  value       = azurerm_cosmosdb_sql_database.this.name
}

output "container_names" {
  description = "Names of all SQL containers created."
  value       = [for c in azurerm_cosmosdb_sql_container.this : c.name]
}
