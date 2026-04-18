#!/usr/bin/env bash
###############################################################################
# bootstrap-backend.sh
#
# Creates the Azure Storage Account that holds remote Terraform state.
# Run ONCE per subscription before `terraform init`.
#
# Usage:
#   ./scripts/bootstrap-backend.sh <location>
#
# Example:
#   ./scripts/bootstrap-backend.sh centralus
###############################################################################
set -euo pipefail

LOCATION="${1:-centralus}"

RG_NAME="rg-tfstate"
SA_NAME="sttfstatecricket$(date +%s | tail -c 6)" # suffix for global uniqueness
CONTAINER_NAME="tfstate"

echo "Creating resource group $RG_NAME in $LOCATION..."
az group create --name "$RG_NAME" --location "$LOCATION" --output none

echo "Creating storage account $SA_NAME..."
az storage account create \
    --name "$SA_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --encryption-services blob \
    --allow-blob-public-access false \
    --min-tls-version TLS1_2 \
    --output none

echo "Enabling blob versioning + soft delete (protects state)..."
az storage account blob-service-properties update \
    --account-name "$SA_NAME" \
    --resource-group "$RG_NAME" \
    --enable-versioning true \
    --enable-delete-retention true --delete-retention-days 14 \
    --output none

echo "Creating container $CONTAINER_NAME..."
az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$SA_NAME" \
    --auth-mode login \
    --output none

cat <<EOF

Backend ready. Add to your init command:

    terraform init \\
      -backend-config="resource_group_name=$RG_NAME" \\
      -backend-config="storage_account_name=$SA_NAME" \\
      -backend-config="container_name=$CONTAINER_NAME" \\
      -backend-config="key=dev.terraform.tfstate"

Record $SA_NAME somewhere safe — you'll need it for every init.
EOF
