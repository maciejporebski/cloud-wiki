param(
    [string]$Organization,
    [string]$Project
)

# Base64 encode the PAT
$token = Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798'
$headers = @{ 'Authorization' = "Bearer $($token.Token)"; 'Content-Type' = 'application/json' }

function Get-RecentPullRequests {
    $uri = "https://dev.azure.com/$organization/$project/_apis/git/pullrequests?searchCriteria.status=completed&api-version=6.0"
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    return $response.value
}

# Retrieve recent pull requests
$pullRequests = Get-RecentPullRequests

# Initialize an array to hold the pull request data
$pullRequestData = @()

# Process each pull request
foreach ($pr in $pullRequests) {
    $creationTime = [datetime]$pr.creationDate
    $completionTime = [datetime]$pr.closedDate
    $timeDelta = $completionTime - $creationTime

    $pullRequestData += [PSCustomObject]@{
        PullRequestId  = $pr.pullRequestId
        Title          = $pr.title
        CreationTime   = $creationTime
        CompletionTime = $completionTime
        TimeDelta      = $timeDelta
        Author         = $pr.createdBy.displayName
        ApprovedBy     = ($pr.reviewers.displayName | Where-Object { $_ -notlike "*]*" }) -join ", "
    }
}

$pullRequestData | Out-GridView
