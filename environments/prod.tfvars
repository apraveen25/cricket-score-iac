# Prod — stronger isolation, Premium Service Bus for Private Endpoint support,
# Standard SWA for custom domain SSL + private linking.

project        = "cricket"
environment    = "prod"
location       = "centralus"
location_short = "cus"

vnet_address_space = ["10.40.0.0/16"]
subnets = {
  app = {
    address_prefixes        = ["10.40.1.0/24"]
    delegate_to_app_service = true
  }
  data = {
    address_prefixes = ["10.40.2.0/24"]
  }
  integration = {
    address_prefixes = ["10.40.3.0/24"]
  }
}

app_service_sku   = "P1v3"    # zonal-ready production plan
servicebus_sku    = "Premium" # required for private endpoint + MI isolation
cosmos_throughput = 1000      # headroom; still low-tier

static_web_app_sku = "Standard"

tags = {
  application = "cricket-score"
  owner       = "platform-team"
  criticality = "high"
}
