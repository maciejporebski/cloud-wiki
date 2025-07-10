param(
    [string]$OutputFile = 'multi-tenant-apps.csv'
)

$apps = Get-MgApplication -Filter "signInAudience in ('AzureADMultipleOrgs', 'AzureADandPersonalMicrosoftAccount' ,'PersonalMicrosoftAccount')"
$apps | Select-Object -Property Id, AppId, DisplayName, SignInAudience

$apps | Export-Csv -Path $OutputFile