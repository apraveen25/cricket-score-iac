output "vnet_id" {
  description = "ID of the Virtual Network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet key -> subnet ID."
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone key -> ID."
  value       = { for k, z in azurerm_private_dns_zone.this : k => z.id }
}

output "private_dns_zone_names" {
  description = "Map of private DNS zone key -> name."
  value       = { for k, z in azurerm_private_dns_zone.this : k => z.name }
}
