param(
    $Organisation = ""
)

$baseUrl = "https://dev.azure.com/$($Organisation)"
$baseReleaseUrl = "https://vsrm.dev.azure.com/$($Organisation)"

$token = Get-AzAccessToken -ResourceUrl '499b84ac-1321-427f-aa17-267ca6975798'
$headers = @{ 'Authorization' = "Bearer $($token.Token)"; 'Content-Type' = 'application/json' }

Write-Host "Fetching Projects..."
$projectsUrl = "$($baseUrl)/_apis/projects?`$top=9999&api-version=6.0"
$projectsReq = Invoke-WebRequest -Uri $projectsUrl -Method Get -Headers $headers
$projects = ($projectsReq | ConvertFrom-Json).value

$buildDefinitions = [pscustomobject]@()
$releaseDefinitions = [pscustomobject]@()
$repositories = [pscustomobject]@()
foreach ($project in $projects) {
    Write-Host "Fetching resources from $($project.name)..."
    $buildDefinitionsUrl = "$($baseUrl)/$($project.id)/_apis/build/definitions?`$top=9999&includeLatestBuilds=true&api-version=6.0"
    $buildDefinitionsReq = Invoke-WebRequest -Uri $buildDefinitionsUrl -Method Get -Headers $headers
    $projectBuildDefinitions = ($buildDefinitionsReq | ConvertFrom-Json).value
    $buildDefinitions += $projectBuildDefinitions

    $releaseDefinitionsUrl = "$($baseReleaseUrl)/$($project.id)/_apis/release/definitions?`$top=9999&api-version=6.0"
    $releaseDefinitionsReq = Invoke-WebRequest -Uri $releaseDefinitionsUrl -Method Get -Headers $headers
    $projectReleaseDefinitions = ($releaseDefinitionsReq | ConvertFrom-Json).value
    $releaseDefinitions += $projectReleaseDefinitions

    $repositoriesUrl = "$($baseUrl)/$($project.id)/_apis/git/repositories?api-version=6.0"
    $repositoriesReq = Invoke-WebRequest -Uri $repositoriesUrl -Method Get -Headers $headers
    $projectRepositories = ($repositoriesReq | ConvertFrom-Json).value
    $repositories += $projectRepositories
}

Write-Host "-----------------------------"
Write-Host "TOTALS:"
Write-Host "-----------------------------"

Write-Host "Projects: " -ForegroundColor Blue -NoNewline
Write-Host $projects.count

Write-Host "Build Definitions: " -ForegroundColor Blue -NoNewline
Write-Host $buildDefinitions.Count
Write-Host "Release Definitions: " -ForegroundColor Blue -NoNewline
Write-Host $releaseDefinitions.Count

Write-Host "Repositories: " -ForegroundColor Blue -NoNewline
Write-Host $repositories.Count
