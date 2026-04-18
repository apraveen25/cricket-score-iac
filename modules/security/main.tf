###############################################################################
# modules/security/main.tf
# Creates:
#   - User-assigned managed identity used by the backend API
#   - Azure Key Vault (RBAC-model), for storing any secrets the app needs
#   - RBAC assignment granting the API identity `Key Vault Secrets User` —
#     enough to read secrets at runtime, not enough to manage them.
###############################################################################

data "azurerm_client_config" "current" {}

###############################################################################
# User-assigned Managed Identity
# Having a UAMI (rather than only a System-assigned identity) lets us grant
# RBAC *before* the App Service is created, avoiding a chicken-and-egg problem
# during the first apply.
###############################################################################
resource "azurerm_user_assigned_identity" "api" {
  name                = var.identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

###############################################################################
# Key Vault (RBAC model — more modern than access policies)
###############################################################################
resource "azurerm_key_vault" "this" {
  name                          = var.key_vault_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  purge_protection_enabled      = false # demo environment — makes cleanup easier
  soft_delete_retention_days    = 7
  public_network_access_enabled = true # cut down to false in prod + add a PE

  # Default deny, allow only from trusted Azure services. In prod you would add
  # a private endpoint and set the default action to "Deny".
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# Grant the deploying principal admin rights so Terraform / operators can manage
# secrets after creation. In CI this is the service principal running apply.
resource "azurerm_role_assignment" "kv_admin_current" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant the API's managed identity read-only access to secrets.
resource "azurerm_role_assignment" "kv_secrets_user_api" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.api.principal_id
}
