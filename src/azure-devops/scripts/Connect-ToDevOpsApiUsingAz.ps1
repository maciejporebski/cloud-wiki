# You must be authenticated with the 'Az' Module by using Connect-AzAccount (https://docs.microsoft.com/en-us/powershell/azure/authenticate-azureps) or be running in an environment such as Azure Cloud Shell or AzurePowershell Azure Pipelines task with authentication already handled to successfully get tokens for Azure DevOps using 'Get-AzAccessToken'.

$devOpsToken = Get-AzAccessToken -ResourceUrl "499b84ac-1321-427f-aa17-267ca6975798"
$headers = @{ 'Authorization' = "Bearer $($devOpsToken.Token)"; 'Content-Type' = 'application/json' }
