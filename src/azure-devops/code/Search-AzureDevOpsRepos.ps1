Param(
    $Organisation,
    $SearchString,
    $OutputFile,
    $MaxResults = 1000
)

$token = Get-AzAccessToken -ResourceUrl "499b84ac-1321-427f-aa17-267ca6975798"
$headers = @{ 'Authorization' = "Bearer $($token.Token)"; 'Content-Type' = 'application/json' }
$searchUri = "https://almsearch.dev.azure.com/$($Organisation)/_apis/search/codeAdvancedQueryResults?api-version=5.0-preview.1"
$searchBody = @{
    searchText = $SearchString
    takeResults = $MaxResults
    includeSuggestions = $false
} | ConvertTo-Json
$searchRequest = Invoke-WebRequest -Uri $searchUri -Method Post -Headers $headers -Body $searchBody
$searchResults = ($searchRequest | ConvertFrom-Json).results.values

$csv = [pscustomobject]@()
foreach($result in $searchResults) {
    $csv += [pscustomobject]@{
        project = $result.project
        repository = $result.repository
        path = $result.path
    }
}

$csv | Export-Csv -Path $OutputFile -NoTypeInformation