# Get a token from the managed identity endpoint bypassing/purging the cached token.

$resource = ""

$endpoint = $env:IDENTITY_ENDPOINT
$header = $env:IDENTITY_HEADER
$apiVersion = "2019-08-01"

$headers = @{ 'X-Identity-Header' = $header }

$url = "$($endpoint)?api-version=$apiVersion&resource=$resource&bypass_cache=true"

$response = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
$response.access_token
