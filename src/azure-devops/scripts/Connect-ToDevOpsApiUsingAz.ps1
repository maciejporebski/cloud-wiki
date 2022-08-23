$devOpsToken = Get-AzAccessToken -ResourceUrl "499b84ac-1321-427f-aa17-267ca6975798"
$headers = @{ 'Authorization' = "Bearer $($devOpsToken.Token)"; 'Content-Type' = 'application/json' }
