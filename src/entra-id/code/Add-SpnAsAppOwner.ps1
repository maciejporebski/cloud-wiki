param(
    [string]$OwnerSpnName,
    [string]$OwnerSpnObjectId = $null,
    [string]$TargetAppName,
    [string]$TargetAppObjectId = $null
)

# Retrieve Owner Id
if (![string]::IsNullOrWhiteSpace($OwnerSpnObjectId)) {
    $ownerObjectId = $OwnerSpnObjectId
}
elseif (![string]::IsNullOrWhiteSpace($OwnerSpnName)) {
    $owner = Get-MgServicePrincipal -Filter "displayName eq '$($OwnerSpnName)'"
    if ($owner.Count -ne 1) {
        throw "Found $($owner.Count) Service Principals named '$($OwnerSpnName)'. Ensure a single Service Principal exists with the specified name or provide 'OwnerSpnObjectId' instead."
    }
    $ownerObjectId = $owner.Id
}
else {
    throw "Either 'OwnerSpnName' or 'OwnerSpnObjectId' parameter must be provided."
}
$ownerParameters = @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($ownerObjectId)" }

# Retrieve Target Ids
if (![string]::IsNullOrWhiteSpace($TargetAppObjectId)) {
    $targetAppObjectId = $TargetAppObjectId
    $targetApp = Get-MgApplication -ApplicationId $targetAppObjectId
}
elseif (![string]::IsNullOrWhiteSpace($TargetAppName)) {
    $targetApp = Get-MgApplication -Filter "displayName eq '$($TargetAppName)'"
    if ($targetApp.Count -ne 1) {
        throw "Found $($targetApp.Count) Service Principals named '$($TargetAppName)'. Ensure a single App Registration exists with the specified name or provide 'TargetAppObjectId' instead."
    }
    $targetAppObjectId = $targetApp.Id
}
else {
    throw "Either 'TargetAppName' or 'TargetAppObjectId' parameter must be provided."
}
$targetSpn = Get-MgServicePrincipal -Filter "AppId eq '$($targetApp.AppId)'"
$targetSpnObjectId = $targetSpn.Id

# Add Owner to App Registration
Write-Host "Adding '$($ownerObjectId)' as owner of '$($targetAppObjectId)' App Registration."
New-MgApplicationOwnerByRef -ApplicationId $targetAppObjectId -BodyParameter $ownerParameters
# Add Owner to Service Principal
Write-Host "Adding '$($ownerObjectId)' as owner of '$($targetSpnObjectId)' Service Principal."
New-MgServicePrincipalOwnerByRef -ServicePrincipalId $targetSpnObjectId  -BodyParameter $ownerParameters
