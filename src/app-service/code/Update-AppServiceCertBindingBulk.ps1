param(
    [string]$DomainToMatch,
    [string]$NewThumbprint
)

$queryString = "resources|where type=='microsoft.web/sites'|where tostring(properties.hostNames) contains '$($DomainToMatch)'|project id,hostnames=properties.hostNames,bindings=properties.hostNameSslStates"
$query = Search-AzGraph -Query $queryString -First 1000

$reqs = @()
foreach ($app in $query) { 

    $matchedHostname = $app.hostnames | Where-Object {$_ -like "*.$($DomainToMatch)"}
 
    $reqs += @{
        httpMethod  = "PUT"
        name        = (New-Guid).Guid
        relativeUrl = "$($app.id)/hostNameBindings/$($matchedHostname)?api-version=2022-03-01"
        content     = @{
            properties = @{
                sslState   = "SniEnabled"
                thumbprint = $NewThumbprint
            }
        }
    }
}
 
$smallerLists = @()
$chunkSize = 20
for ($i = 0; $i -lt $reqs.Count; $i += $chunkSize) {
    $smallerLists += ,($reqs[$i..($i + $chunkSize - 1)])
}
 
foreach($list in $smallerLists) {
    $batchUrl = "https://management.azure.com/batch?api-version=2022-12-01"
    $batchBody = @{ requests = $list } | ConvertTo-Json -Depth 5
    $token = Get-AzAccessToken
    $headers = @{ Authorization = "Bearer $($token.Token)"; 'Content-Type' = 'application/json' }
    $batchReq = Invoke-WebRequest -Uri $batchUrl -Method Post -Headers $headers -Body $batchBody
 
    $batchReq.StatusCode
}