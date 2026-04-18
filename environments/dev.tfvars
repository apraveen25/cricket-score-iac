# Dev — cheapest viable setup.

project        = "cricket"
environment    = "dev"
location       = "centralus"
location_short = "cus"

app_service_sku   = "B1"
servicebus_sku    = "Standard" # Premium ($$$) not needed in dev
cosmos_throughput = 400        # absolute minimum
static_web_app_sku = "Free"

tags = {
  application = "cricket-score"
  owner       = "dev-team"
}
