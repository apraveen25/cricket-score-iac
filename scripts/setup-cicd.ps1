<#
.SYNOPSIS
    One-shot CI/CD bootstrap for GitHub Actions to Azure (OIDC).

.DESCRIPTION
    Creates an Entra ID app registration + service principal, grants it
    Contributor + User Access Administrator on the subscription, registers
    federated credentials for push-to-main / pull-request / the three
    GitHub Environments, and prints the three secrets you need to paste into
    GitHub repo settings.

    Run AFTER `bootstrap-backend.ps1`. You must already be logged in with
    an account that can create app registrations and assign subscription-
    level RBAC (Owner or Privileged Role Administrator + User Access Admin).

.PARAMETER Repo
    GitHub repo slug, e.g. "praveenaenugu/cricket-score-iac".

.PARAMETER AppName
    Display name for the app registration.

.PARAMETER StorageAccount
    Name of the Terraform state storage account (from bootstrap-backend.ps1).
    Used to grant the SP Storage Blob Data Contributor on the state account.

.PARAMETER StorageResourceGroup
    Resource group holding the state storage account.

.EXAMPLE
    PS> az login
    PS> az account set --subscription "My Subscription"
    PS> .\scripts\setup-cicd.ps1 `
            -Repo "praveenaenugu/cricket-score-iac" `
            -StorageAccount "sttfstatecricket12345"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Repo,

    [string]$AppName               = "sp-github-cricket-score-iac",
    [string]$StorageAccount,
    [string]$StorageResourceGroup  = "rg-tfstate",
    [string[]]$Environments        = @("dev","test","prod")
)

$ErrorActionPreference = "Stop"

# -----------------------------------------------------------------------------
# 1. Capture subscription + tenant from the active az CLI context
# -----------------------------------------------------------------------------
$SubscriptionId = az account show --query id       -o tsv
$TenantId       = az account show --query tenantId -o tsv

if (-not $SubscriptionId) {
    throw "Not logged in. Run 'az login' first."
}

Write-Host "Subscription : $SubscriptionId" -ForegroundColor Cyan
Write-Host "Tenant       : $TenantId"       -ForegroundColor Cyan
Write-Host "Repo         : $Repo"           -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# 2. Create (or reuse) the app registration + service principal
# -----------------------------------------------------------------------------
Write-Host "`nCreating app registration '$AppName'..." -ForegroundColor Cyan
$AppId = az ad app list --display-name $AppName --query "[0].appId" -o tsv
if (-not $AppId) {
    $AppId = az ad app create --display-name $AppName --query appId -o tsv
    az ad sp create --id $AppId | Out-Null
} else {
    Write-Host "  (already exists -- reusing $AppId)" -ForegroundColor DarkGray
}
$ObjectId = az ad app show --id $AppId --query id -o tsv

Write-Host "AppId        : $AppId"
Write-Host "ObjectId     : $ObjectId"

# -----------------------------------------------------------------------------
# 3. Grant subscription-level RBAC
#    Contributor               -> create/destroy Azure resources
#    User Access Administrator -> assign RBAC (Cosmos, Service Bus, Key Vault)
# -----------------------------------------------------------------------------
Write-Host "`nGranting subscription RBAC..." -ForegroundColor Cyan
foreach ($role in @("Contributor", "User Access Administrator")) {
    az role assignment create `
        --assignee     $AppId `
        --role         $role `
        --scope        "/subscriptions/$SubscriptionId" `
        --only-show-errors | Out-Null
    Write-Host "  granted: $role"
}

# -----------------------------------------------------------------------------
# 4. Grant access to the Terraform state storage account (if provided)
# -----------------------------------------------------------------------------
if ($StorageAccount) {
    Write-Host "`nGranting Storage Blob Data Contributor on $StorageAccount..." -ForegroundColor Cyan
    $saId = az storage account show `
        --name           $StorageAccount `
        --resource-group $StorageResourceGroup `
        --query id -o tsv
    az role assignment create `
        --assignee        $AppId `
        --role            "Storage Blob Data Contributor" `
        --scope           $saId `
        --only-show-errors | Out-Null
    Write-Host "  granted on: $saId"
}

# -----------------------------------------------------------------------------
# 5. Federated credentials -- one per GitHub OIDC subject we care about
# -----------------------------------------------------------------------------
function New-FederatedCredential {
    param([string]$Name, [string]$Subject)

    # az CLI wants JSON parameters; use a temp file to avoid shell-escaping pain.
    $params = @{
        name      = $Name
        issuer    = "https://token.actions.githubusercontent.com"
        subject   = $Subject
        audiences = @("api://AzureADTokenExchange")
    } | ConvertTo-Json -Compress

    $tmp = New-TemporaryFile
    Set-Content -Path $tmp -Value $params -Encoding utf8

    # Ignore "already exists" errors so the script is idempotent.
    az ad app federated-credential create `
        --id         $ObjectId `
        --parameters "@$tmp" `
        --only-show-errors 2>$null | Out-Null

    Remove-Item $tmp -Force
    Write-Host "  $Name -> $Subject"
}

Write-Host "`nRegistering federated credentials..." -ForegroundColor Cyan
New-FederatedCredential -Name "gh-main" -Subject "repo:${Repo}:ref:refs/heads/main"
New-FederatedCredential -Name "gh-pr"   -Subject "repo:${Repo}:pull_request"

foreach ($env in $Environments) {
    New-FederatedCredential -Name "gh-env-$env" -Subject "repo:${Repo}:environment:$env"
}

# -----------------------------------------------------------------------------
# 6. Tell the user what to paste into GitHub
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " Add these THREE secrets in GitHub -> Settings -> Secrets and" -ForegroundColor Green
Write-Host " variables -> Actions:" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  AZURE_CLIENT_ID       = $AppId"
Write-Host "  AZURE_TENANT_ID       = $TenantId"
Write-Host "  AZURE_SUBSCRIPTION_ID = $SubscriptionId"
Write-Host ""
Write-Host "Then create the three GitHub Environments (dev, test, prod) in" -ForegroundColor Yellow
Write-Host "Settings -> Environments, and add required reviewers for test/prod." -ForegroundColor Yellow
