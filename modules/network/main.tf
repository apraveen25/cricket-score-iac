###############################################################################
# modules/network/main.tf
# Creates:
#   - Virtual Network
#   - Subnets (app / data / integration)  — delegations + service endpoints
#   - NSGs with least-privilege defaults, one per subnet
#   - Private DNS Zones linked to the VNET (for private endpoints)
###############################################################################

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  tags                = var.tags
}

###############################################################################
# Subnets
###############################################################################
resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = "snet-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  # Private endpoints need this turned OFF (the default). For App Service VNET
  # integration we explicitly delegate.
  private_endpoint_network_policies = "Enabled"

  dynamic "delegation" {
    for_each = each.value.delegate_to_app_service ? [1] : []
    content {
      name = "appservice-delegation"
      service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}

###############################################################################
# Network Security Groups — one per subnet with a minimal baseline.
# Azure applies default rules (AllowVnetInBound / DenyAllInBound, etc.) so
# we only declare what we need to *add*, keeping the rule set tight.
###############################################################################
resource "azurerm_network_security_group" "this" {
  for_each = var.subnets

  name                = "nsg-snet-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Allow HTTPS within the VNET (App Service inbound, private endpoints, etc.).
  security_rule {
    name                       = "AllowHttpsFromVnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Explicit deny of inbound internet — defense in depth on top of the default.
  security_rule {
    name                       = "DenyInboundInternet"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

###############################################################################
# Private DNS Zones — linked to the VNET so private endpoint A records resolve
# automatically from anything running in the VNET.
###############################################################################
resource "azurerm_private_dns_zone" "this" {
  for_each = var.private_dns_zones

  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.private_dns_zones

  name                  = "link-${each.key}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}
