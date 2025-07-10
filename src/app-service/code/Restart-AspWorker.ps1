param (
    [parameter(Position = 0, Mandatory = $false)]
    [string]
    $WorkerResourceId
)

$token = Get-AzAccessToken
$headers = @{ 'Authorization' = "Bearer $($token.Token)"; 'Content-Type' = 'application/json' }

Write-Host "You are about to restart App Service Plan Worker '$($WorkerResourceId)'"
$confirmation = $Host.UI.PromptForChoice("Restarting '$($WorkerResourceId)'",'Are you sure you want to proceed?', @('&No','&Yes'), 0)
if ($confirmation -eq 1) {
    $restartUri = "https://management.azure.com$($WorkerResourceId)/reboot?api-version=2021-02-01"
    $restartReq = Invoke-WebRequest -Uri $restartUri -Method Post -Headers $headers
    if($restartReq.StatusCode -eq 200) {
        Write-Host "Restarted Successfully."
    }
} else {
    Write-Host "Skipping restart."
}
