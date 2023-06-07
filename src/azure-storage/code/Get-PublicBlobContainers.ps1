param(
    [string]$OutputFile
)

$allContainers = [pscustomobject]@()

$token = Get-AzAccessToken
$tenants = (Invoke-WebRequest -Uri "https://management.azure.com/tenants?api-version=2022-12-01" -Headers @{ 'Authorization' = "Bearer $($token.Token)" } | ConvertFrom-Json).value
$aadTenants = $tenants | Where-Object { $_.tenantType -eq 'AAD' }

foreach ($aadTenant in $aadTenants) {
    Write-Host "$($aadTenant.displayName)"

    $token = Get-AzAccessToken -TenantId $aadTenant.tenantId
    $subscriptions = (Invoke-WebRequest -Uri "https://management.azure.com/subscriptions?api-version=2022-12-01" -Headers @{ 'Authorization' = "Bearer $($token.Token)" } | ConvertFrom-Json).value

    foreach ($subscription in $subscriptions) {
        Write-Host "    $($subscription.displayName)"

        $storageAccounts = (Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$($subscription.subscriptionId)/providers/Microsoft.Storage/storageAccounts?api-version=2022-09-01" -Headers @{ 'Authorization' = "Bearer $($token.Token)" } | ConvertFrom-Json).value
        $storageAccountsWithBlobSupport = $storageAccounts | Where-Object { $_.kind -ne 'FileStorage' }
        foreach ($storageAccount in $storageAccountsWithBlobSupport) {
            Write-Host "        $($storageAccount.name)"

            $accountContainers = (Invoke-WebRequest -Uri "https://management.azure.com$($storageAccount.id)/blobServices/default/containers?api-version=2022-09-01" -Headers @{ 'Authorization' = "Bearer $($token.Token)" } | ConvertFrom-Json).value
            foreach ($accountContainer in $accountContainers) {
                Write-Host "            $($accountContainer.name)"

                $allContainers += [pscustomobject]@{
                    subscription                 = $subscription.displayName
                    storageAccount               = $storageAccount.name
                    container                    = $accountContainer.name
                    accountAllowsPublicAccess    = $storageAccount.properties.allowBlobPublicAccess
                    accountFirewallDefaultAction = $storageAccount.properties.networkAcls.defaultAction
                    containerPublicAccessLevel   = $accountContainer.properties.publicAccess
                }
            }
        }
    }
}

$allContainers | Export-Csv -Path $OutputFile
