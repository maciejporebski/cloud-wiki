$resource = ""

$endpoint = $env:IDENTITY_ENDPOINT
$header = $env:IDENTITY_HEADER
$apiVersion = "2019-08-01"

$headers = @{ 'X-Identity-Header' = $header }

$url = "$($endpoint)?api-version=$apiVersion&resource=$resource"

$response = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
$token = $response.access_token