param(
    [string]$GroupName,
    [string]$SpnName
)

$group = Get-MgGroup -Filter "displayName eq '$($GroupName)'"
$spn = Get-MgServicePrincipal -Filter "displayName eq '$($SpnName)'"
$params = @{
	"@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($spn.Id)"
}
New-MgGroupOwnerByRef -GroupId $group.Id -BodyParameter $params
