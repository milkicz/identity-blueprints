<#
.SYNOPSIS
Creates a service principal in the target tenant for a multi-tenant app registration
from the source tenant and grants admin consent for its required permissions.

.PARAMETER AppId
The Application (client) ID of the multi-tenant app registration from the source tenant.

.NOTES
Requires to connect to ms graph first, e.g.:
Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All" -TenantId ""
Connect as an administrator of the target tenant.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$AppId
)

# Confirm current context
$context = Get-MgContext
Write-Host "Connected as: $($context.Account)" -ForegroundColor Cyan

# Check if a service principal for this app already exists in the target tenant
$existingSp = Get-MgServicePrincipal -Filter "appId eq '$AppId'" -ErrorAction SilentlyContinue

if ($existingSp) {
    Write-Host "Service principal for AppId '$AppId' already exists in this tenant (ObjectId: $($existingSp.Id)). Skipping creation." -ForegroundColor Yellow
    $sp = $existingSp
}
else {
    # Create the service principal in the target tenant
    $sp = New-MgServicePrincipal -AppId $AppId -ErrorAction Stop
    Write-Host "Service principal created for AppId '$AppId' (ObjectId: $($sp.Id), DisplayName: $($sp.DisplayName))." -ForegroundColor Green
}

# Grant admin consent by assigning required app roles
$requiredAccess = $sp.RequiredResourceAccess

if (-not $requiredAccess -or $requiredAccess.Count -eq 0) {
    Write-Host "No required resource access defined for this application. Nothing to consent." -ForegroundColor Yellow
    exit
}

foreach ($resource in $requiredAccess) {
    # Get the resource service principal (e.g., Microsoft Graph)
    $resourceSp = Get-MgServicePrincipal -Filter "appId eq '$($resource.ResourceAppId)'"

    if (-not $resourceSp) {
        Write-Warning "Resource service principal with AppId '$($resource.ResourceAppId)' not found in this tenant. Skipping."
        continue
    }

    Write-Host "Processing permissions for resource: $($resourceSp.DisplayName)" -ForegroundColor Cyan

    # Filter for application-type permissions (Role), skip delegated (Scope)
    $appRoleRequests = $resource.ResourceAccess | Where-Object { $_.Type -eq "Role" }

    if (-not $appRoleRequests -or $appRoleRequests.Count -eq 0) {
        Write-Host "  No application permissions requested for '$($resourceSp.DisplayName)'. Skipping." -ForegroundColor Yellow
        continue
    }

    # Get existing app role assignments
    $existingAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id

    foreach ($roleRequest in $appRoleRequests) {
        # Resolve app role name for display
        $appRole = $resourceSp.AppRoles | Where-Object { $_.Id -eq $roleRequest.Id }
        $roleName = if ($appRole) { $appRole.Value } else { $roleRequest.Id }

        # Check if already assigned
        $alreadyAssigned = $existingAssignments | Where-Object {
            $_.AppRoleId -eq $roleRequest.Id -and $_.ResourceId -eq $resourceSp.Id
        }

        if ($alreadyAssigned) {
            Write-Host "  '$roleName' is already consented. Skipping." -ForegroundColor Yellow
        }
        else {
            New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id `
                -PrincipalId $sp.Id `
                -ResourceId $resourceSp.Id `
                -AppRoleId $roleRequest.Id | Out-Null

            Write-Host "  '$roleName' permission granted (admin consent)." -ForegroundColor Green
        }
    }
}

Write-Host "Admin consent completed for service principal '$($sp.DisplayName)'." -ForegroundColor Green