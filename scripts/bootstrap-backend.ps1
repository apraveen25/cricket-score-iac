<#
.SYNOPSIS
    Bootstraps the Azure Storage Account that holds remote Terraform state.

.DESCRIPTION
    Run ONCE per subscription before `terraform init`.
    Creates:
      - Resource group  rg-tfstate
      - Storage account sttfstatecricket<suffix>  (LRS, TLS 1.2, no public blobs)
      - Blob container  tfstate                   (versioning + soft-delete on)

.PARAMETER Location
    Azure region. Defaults to "centralus".

.EXAMPLE
    PS> .\scripts\bootstrap-backend.ps1
    PS> .\scripts\bootstrap-backend.ps1 -Location eastus2
#>

[CmdletBinding()]
param(
    [string]$Location      = "centralus",
    [string]$ResourceGroup = "rg-tfstate",
    [string]$Container     = "tfstate"
)

$ErrorActionPreference = "Stop"

# Short numeric suffix for global uniqueness. Get-Random is locale-safe and
# gives a 5-digit number; storage account names must be 3-24 chars, lowercase
# alphanumeric only, so the "sttfstatecricket" prefix (16 chars) + 5 digits
# = 21 chars, well within the limit.
$suffix         = Get-Random -Minimum 10000 -Maximum 100000
$StorageAccount = "sttfstatecricket$suffix"

Write-Host "Creating resource group $ResourceGroup in $Location..." -ForegroundColor Cyan
az group create `
    --name     $ResourceGroup `
    --location $Location `
    --output   none

Write-Host "Creating storage account $StorageAccount..." -ForegroundColor Cyan
az storage account create `
    --name                      $StorageAccount `
    --resource-group            $ResourceGroup `
    --location                  $Location `
    --sku                       Standard_LRS `
    --encryption-services       blob `
    --allow-blob-public-access  false `
    --min-tls-version           TLS1_2 `
    --output                    none

Write-Host "Enabling blob versioning + soft delete (protects state)..." -ForegroundColor Cyan
az storage account blob-service-properties update `
    --account-name             $StorageAccount `
    --resource-group           $ResourceGroup `
    --enable-versioning        true `
    --enable-delete-retention  true `
    --delete-retention-days    14 `
    --output                   none

Write-Host "Creating container $Container..." -ForegroundColor Cyan
az storage container create `
    --name          $Container `
    --account-name  $StorageAccount `
    --auth-mode     login `
    --output        none

Write-Host ""
Write-Host "Backend ready. Use these values for 'terraform init':" -ForegroundColor Green
Write-Host ""
Write-Host "  terraform init ``"
Write-Host "    -backend-config=`"resource_group_name=$ResourceGroup`" ``"
Write-Host "    -backend-config=`"storage_account_name=$StorageAccount`" ``"
Write-Host "    -backend-config=`"container_name=$Container`" ``"
Write-Host "    -backend-config=`"key=dev.terraform.tfstate`""
Write-Host ""
Write-Host "Record the storage account name '$StorageAccount' -- you will need it every init." -ForegroundColor Yellow
