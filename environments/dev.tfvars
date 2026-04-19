# Dev — cheapest viable setup.

subscription_id="820d29fa-ea5f-4a5a-a9ef-9b4bc67f7c4b"
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
