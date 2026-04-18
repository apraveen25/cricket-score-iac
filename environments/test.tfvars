# Test — mirrors dev but on a separate address space so both can coexist in
# the same subscription without VNET collisions.

project        = "cricket"
environment    = "test"
location       = "centralus"
location_short = "cus"

vnet_address_space = ["10.30.0.0/16"]
subnets = {
  app = {
    address_prefixes        = ["10.30.1.0/24"]
    delegate_to_app_service = true
  }
  data = {
    address_prefixes = ["10.30.2.0/24"]
  }
  integration = {
    address_prefixes = ["10.30.3.0/24"]
  }
}

app_service_sku   = "B1"
servicebus_sku    = "Standard"
cosmos_throughput = 400
static_web_app_sku = "Free"

tags = {
  application = "cricket-score"
  owner       = "qa-team"
}
