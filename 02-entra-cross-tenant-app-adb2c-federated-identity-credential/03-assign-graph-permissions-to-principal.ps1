<#
.SYNOPSIS
Assigns the Microsoft Graph application permission to a managed identity (service principal).

.PARAMETER ManagedIdentityObjectId
The Object ID of the managed identity's service principal in Entra ID (Azure AD).
.

.PARAMETER PermissionsToGrant
An array of Microsoft Graph application permissions to assign to the managed identity. e.g., @("User.Read.All", "Group.ReadWrite.All")

.NOTES
Requires to connect to ms graph first, e.g.:
Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All" -TenantId ""
Connect as local administrator of the target tenant
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ManagedIdentityObjectId,
    [Parameter(Mandatory = $true)]
    [object]$PermissionsToGrant
)

# Confirm current context
$context = Get-MgContext
Write-Host "Connected as: $($context.Account)" -ForegroundColor Cyan

# Microsoft Graph service principal (fixed AppId)
$graphSpAppId = "00000003-0000-0000-c000-000000000000"

# Get Microsoft Graph service principal
$graphSp = Get-MgServicePrincipal -Filter "appId eq '$graphSpAppId'"

# Get target managed identity service principal
$miSp = Get-MgServicePrincipal -ServicePrincipalId $ManagedIdentityObjectId

if (-not $miSp) {
    Write-Error "Managed identity service principal not found. Check the Object ID."
    exit
}

foreach ($PermissionToGrant in $PermissionsToGrant) {
    # Find the permission app role ID
    $appRole = $graphSp.AppRoles | Where-Object { $_.Value -eq $PermissionToGrant -and $_.AllowedMemberTypes -contains "Application" }

    if (-not $appRole) {
        Write-Error "Could not find '$PermissionToGrant' app role in Microsoft Graph."
        exit
    }

    # Check if already assigned
    $existing = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentityObjectId |
        Where-Object { $_.AppRoleId -eq $appRole.Id -and $_.ResourceId -eq $graphSp.Id }

    if ($existing) {
        Write-Host "'$PermissionToGrant' is already assigned to this managed identity." -ForegroundColor Yellow
    }
    else {
        # Assign the app role
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentityObjectId `
            -PrincipalId $ManagedIdentityObjectId `
            -ResourceId $graphSp.Id `
            -AppRoleId $appRole.Id | Out-Null

        Write-Host "'$PermissionToGrant' permission successfully assigned to managed identity." -ForegroundColor Green
    }
}