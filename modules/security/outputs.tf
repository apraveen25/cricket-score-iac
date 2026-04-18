output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  description = "DNS URI of the Key Vault (used for Key Vault references in App Service)."
  value       = azurerm_key_vault.this.vault_uri
}

output "api_identity_id" {
  description = "Resource ID of the user-assigned identity used by the backend API."
  value       = azurerm_user_assigned_identity.api.id
}

output "api_identity_client_id" {
  description = "Client ID (appId) of the API identity — used by Azure AD auth / MSAL."
  value       = azurerm_user_assigned_identity.api.client_id
}

output "api_identity_principal_id" {
  description = "Object ID (principalId) of the API identity — used as a target for role assignments."
  value       = azurerm_user_assigned_identity.api.principal_id
}
