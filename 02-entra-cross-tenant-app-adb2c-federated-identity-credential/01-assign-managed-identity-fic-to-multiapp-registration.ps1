<#
.SYNOPSIS
Creates a Federated Identity Credential (FIC) on a multi-tenant app registration,
allowing a managed identity to obtain tokens as that application via workload identity federation.

.PARAMETER ApplicationObjectId
The Object ID of the multi-tenant app registration in Entra ID (Azure AD).

.PARAMETER ManagedIdentityObjectId
The Object ID of the managed identity's service principal in Entra ID (Azure AD).

.PARAMETER ManagedIdentityTenantId
The Tenant ID where the managed identity resides.

.PARAMETER FicName
A display name for the federated identity credential.

.PARAMETER Audience
The token audience for the federated identity credential. Defaults to "api://AzureADTokenExchange".

.NOTES
Requires to connect to ms graph first, e.g.:
Connect-MgGraph -Scopes "Application.ReadWrite.All" -TenantId "<home-tenant-id>"
Connect as an administrator of the home tenant where the app registration lives.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ApplicationObjectId,
    [Parameter(Mandatory = $true)]
    [string]$ManagedIdentityObjectId,
    [Parameter(Mandatory = $true)]
    [string]$ManagedIdentityTenantId,
    [Parameter(Mandatory = $true)]
    [string]$FicName,
    [Parameter(Mandatory = $false)]
    [string]$Audience = "api://AzureADTokenExchange"
)

# Confirm current context
$context = Get-MgContext
Write-Host "Connected as: $($context.Account)" -ForegroundColor Cyan

# Validate the app registration exists
$app = Get-MgApplication -ApplicationId $ApplicationObjectId -ErrorAction Stop

if (-not $app) {
    Write-Error "App registration with Object ID '$ApplicationObjectId' not found."
    exit
}

Write-Host "App registration found: $($app.DisplayName) (AppId: $($app.AppId))" -ForegroundColor Cyan

# Validate the managed identity service principal exists
$miSp = Get-MgServicePrincipal -ServicePrincipalId $ManagedIdentityObjectId -ErrorAction Stop

if (-not $miSp) {
    Write-Error "Managed identity service principal with Object ID '$ManagedIdentityObjectId' not found."
    exit
}

Write-Host "Managed identity found: $($miSp.DisplayName)" -ForegroundColor Cyan

# Check if a FIC with the same name already exists
$existingFics = Get-MgApplicationFederatedIdentityCredential -ApplicationId $ApplicationObjectId
$existingFic = $existingFics | Where-Object { $_.Name -eq $FicName }

if ($existingFic) {
    Write-Host "Federated identity credential '$FicName' already exists on app registration '$($app.DisplayName)'. Skipping creation." -ForegroundColor Yellow
}
else {
    # Build the issuer URL from the managed identity's tenant
    $issuer = "https://login.microsoftonline.com/$ManagedIdentityTenantId/v2.0"

    # Create the federated identity credential
    New-MgApplicationFederatedIdentityCredential -ApplicationId $ApplicationObjectId `
        -Name $FicName `
        -Issuer $issuer `
        -Subject $ManagedIdentityObjectId `
        -Audiences @($Audience) `
        -Description "FIC for managed identity '$($miSp.DisplayName)' to authenticate as app '$($app.DisplayName)'" | Out-Null

    Write-Host "Federated identity credential '$FicName' successfully created on app registration '$($app.DisplayName)'." -ForegroundColor Green
}