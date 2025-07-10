param(
    [string]$StorageAccount,
    [string]$ResourceGroup,
    [string]$SourceQueue,
    [string]$TargetQueue
)

$invisibleTimeout = [System.TimeSpan]::FromSeconds(30)
$ErrorActionPreference = 'Stop'

$keys = Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccount
$ctx = New-AzStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $keys[0].Value

$sourceQueue = Get-AzStorageQueue -Context $ctx -Name $SourceQueue
$targetQueue = Get-AzStorageQueue -Context $ctx -Name $TargetQueue

$count = 0
do {
    $queueMessage = $sourceQueue.CloudQueue.GetMessageAsync($invisibleTimeout, $null, $null)
    $targetQueue.CloudQueue.AddMessageAsync($queueMessage.Result)
    Write-Host "Processing $($queueMessage.Id)"
    $count++
    Write-Host "Message Number $($count)"
    $queue.CloudQueue.DeleteMessageAsync($queueMessage.Result.Id,$queueMessage.Result.popReceipt)
} while ($null -ne $queueMessage.Result)
