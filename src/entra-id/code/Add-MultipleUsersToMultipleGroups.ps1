param(
    [string[]]$Groups,
    [string[]]$Users
)

$groupObjects = @()
$userObjects = @()

foreach ($group in $Groups) {
    $groupObjects += Get-MgGroup -Filter "displayName eq '$($group)'"
}

foreach ($user in $Users) {
    $userObjects += Get-MgUser -Filter "mail eq '$($user)'"
}

foreach ($groupObject in $groupObjects) {
    foreach ($userObject in $userObjects) {
        Write-Host "Adding '$($groupObject.DisplayName)' to '$($userObject.DisplayName)'."
        New-MgGroupMemberByRef -GroupId $groupObject.Id -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$($userObject.Id)"
    }
}