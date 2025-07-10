param(
    [Parameter(Mandatory = $true)]
    [string]$Organisation,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$devOpsToken = Get-AzAccessToken -ResourceUrl "499b84ac-1321-427f-aa17-267ca6975798"
$headers = @{ 'Authorization' = "Bearer $($devOpsToken.Token)"; 'Content-Type' = 'application/json' }

$getProjectsUri = "https://dev.azure.com/$($Organisation)/_apis/projects?`$top=9999"
$getProjectsReq = Invoke-WebRequest -Uri $getProjectsUri -Method Get -Headers $headers
$projects = ($getProjectsReq.Content | ConvertFrom-Json).value

$combinedOutput = $projects | ForEach-Object -Parallel {
    $project = $_
    $headers = $using:headers
    $Organisation = $using:Organisation
    
    $getYamlPipelinesUri = "https://dev.azure.com/$($Organisation)/$($project.id)/_apis/pipelines?api-version=6.0-preview.1"
    $getYamlPipelinesReq = Invoke-WebRequest -Uri $getYamlPipelinesUri -Method Get -Headers $headers
    $yamlPipelines = ($getYamlPipelinesReq.Content | ConvertFrom-Json).value
    
    $yamlOutput = $yamlPipelines | ForEach-Object -Parallel {
        $yamlPipeline = $_
        $project = $using:project
        $headers = $using:headers
        $Organisation = $using:Organisation
        Write-Host "PROJECT: $($project.name)    PIPELINE: $($yamlPipeline.name)"

        $getYamlPipelineLatestBuildUri = "https://dev.azure.com/$($Organisation)/$($project.id)/_apis/build/builds?definitions=$($yamlPipeline.id)&api-version=6.0&`$top=1"
        $getPipelineLatestBuildReq = Invoke-WebRequest -Uri $getYamlPipelineLatestBuildUri -Method Get -Headers $headers
        $latestYamlBuild = ($getPipelineLatestBuildReq | ConvertFrom-Json).value
        
        return [pscustomobject]@{
            project          = $project.name
            type             = 'yaml'
            pipelineName     = $yamlPipeline.name
            pipelineId       = $yamlPipeline.id
            pipelineUri      = $yamlPipeline._links.web.href
            lastRunQueueTime = $latestYamlBuild[0].queueTime
            lastRunUri       = $latestYamlBuild[0].url
            lastRunBy        = $latestYamlBuild.requestedBy.displayName
        }
    } -ThrottleLimit 10

    $getClassicPipelinesUri = "https://vsrm.dev.azure.com/$($Organisation)/$($project.id)/_apis/release/definitions?api-version=6.0"
    $getClassicPipelinesReq = Invoke-WebRequest -Uri $getClassicPipelinesUri -Method Get -Headers $headers
    $classicPipelines = ($getClassicPipelinesReq | ConvertFrom-Json).value

    $classicOutput = $classicPipelines | ForEach-Object -Parallel {
        $classicPipeline = $_
        $project = $using:project
        $headers = $using:headers
        $Organisation = $using:Organisation
        Write-Host "PROJECT: $($project.name)    PIPELINE: $($classicPipeline.name)"
           
        $getClassicPipelineLatestBuildUri = "https://vsrm.dev.azure.com/$($Organisation)/$($project.id)/_apis/release/releases?definitionId=$($classicPipeline.id)&api-version=6.0&`$top=1"
        $getPipelineLatestRelease = Invoke-WebRequest -Uri $getClassicPipelineLatestBuildUri -Method Get -Headers $headers
        $latestClassicRelease = ($getPipelineLatestRelease | ConvertFrom-Json).value

        return [pscustomobject]@{
            project          = $project.name
            type             = 'classic'
            pipelineName     = $classicPipeline.name
            pipelineId       = $classicPipeline.id
            pipelineUri      = $classicPipeline._links.web.href
            lastRunQueueTime = $classicPipeline.createdOn
            lastRunUri       = $latestClassicRelease[0].url
            lastRunBy        = $latestClassicRelease.createdBy.displayName
        }
    } -ThrottleLimit 10

    return @($yamlOutput, $classicOutput)

} -ThrottleLimit 5

$filteredOutput = $combinedOutput | Where-Object { $null -ne $_ }
$flattenedOutput = @($filteredOutput | ForEach-Object { $_ })

$flattenedOutput | Where-Object { $null -ne $_ } | Export-Csv -Path $OutputPath