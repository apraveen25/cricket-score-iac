###############################################################################
# backend.tf
# Remote state in an Azure Storage Account. The state container must exist
# before `terraform init` is run for the first time. See README for the
# bootstrap script.
#
# Values are intentionally left as placeholders; override them at init time:
#
#   terraform init \
#     -backend-config="resource_group_name=rg-tfstate" \
#     -backend-config="storage_account_name=sttfstatecricket" \
#     -backend-config="container_name=tfstate" \
#     -backend-config="key=dev.terraform.tfstate"
###############################################################################

terraform {
  backend "azurerm" {
    # Empty — populated via `-backend-config` flags or a backend-config file
    # so the same root module can serve dev / test / prod environments.
  }
}
