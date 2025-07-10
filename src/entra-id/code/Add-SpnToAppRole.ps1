Param(
    # Service Principal Id of the identity the role is being assigned to.
    # This is the Object ID of the Service Principal resource, not the App Registration resource.
    [Parameter(Mandatory=$true)][string]
    $AssigneeSpnId,
    # Service Principal Id of the Service Principal belonging to the target App which exposes the role.
    # This is the Object ID of the Service Principal resource, not the App Registration resource.
    [Parameter(Mandatory=$true)][string]
    $TargetSpnId,
    # The name of the role being assigned. If a value is not provided the default role is assigned (00000000-0000-0000-0000-000000000000).
    [Parameter(Mandatory=$false)][string]
    $RoleName = $null
)

Connect-MgGraph -AccessToken (ConvertTo-SecureString -String (Get-AzAccessToken -ResourceTypeName MSGraph).Token -AsPlainText) | Out-Null

$targetSpn = Get-MgServicePrincipal -ServicePrincipalId $TargetSpnId -Property AppRoles,DisplayName
if ($RoleName.Length -gt 0) {
    $role = $targetSpn.AppRoles | Where-Object { $_.Value -eq $RoleName }
    $roleId = $role.Id
    if($null -eq $role) {
        throw "Role '$($RoleName)' not found for app '$($targetSpn.DisplayName)'."
    }
}
else {
    $roleId = '00000000-0000-0000-0000-000000000000'
}

New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $AssigneeSpnId `
                                        -PrincipalId $AssigneeSpnId `
                                        -ResourceId $TargetSpnId `
                                        -AppRoleId $roleId
