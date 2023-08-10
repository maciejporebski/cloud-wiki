param(
    [string]$Namespace,
    [string]$Queue,
    [string]$Topic,
    [string]$Subscription,
    [bool]$DeadLeterQueue = $false,
    [int]$MaxMessages = 5
)

if ($Queue.Length -gt 0) {
    $entityPath = $Queue
}
elseif ($Topic.Length -gt 0 -and $Subscription.Length -gt 0) {
    $entityPath = "$($Topic)/subscriptions/$($Subscription)"
}
else {
    throw "Either Queue or Topic and Subscription parameters must be provided."
}

if ($DeadLeterQueue) {
    $entityPath += "/`$DeadLetterQueue"
}

$messageUri = "https://$($Namespace).servicebus.windows.net/$($entityPath)/messages/head?api-version=2015-01"

$token = Get-AzAccessToken -ResourceUrl "https://servicebus.azure.net"
$headers = @{ Authorization = "Bearer $($token.Token)" }

$receivedMessages = 0
$messages = [pscustomobject]@()

do {
    $req = Invoke-WebRequest -Uri $messageUri -Headers $headers

    if ($req.StatusCode -eq 204) {
        Write-Warning "Entity contains no messages."
        exit
    }

    $messageProperties = $req. Headers['BrokerProperties'] | ConvertFrom-Json
    Write-Host "Retrieved Message ID: $($messageProperties.MessageId)"
    $messages += [pscustomobject]@{
        Message         = $req.Content
        MessageId       = $messageProperties.MessageId
        EnqueuedTimeUtc = $messageProperties.EnqueuedTimeUtc
        DeliveryCount   = $messageProperties.DeliveryCount
        State           = $messageProperties.State
        Label           = $messageProperties.Label
    }

    if ($null -ne $req.Headers['Next-Message']) {
        $messageUri = $req.Headers['Next-Message'][0]
    }
    $receivedMessages++
} while (($receivedMessages -lt $MaxMessages) -and ($null -ne $req.Headers['Next-Message']))

if ($null -ne $req.Headers['Next-Message']) {
    Write-Warning "Message limit of $($MaxMessages) exceeded but more messages are present."
}

$messages | Out-GridView