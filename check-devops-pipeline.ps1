#! /usr/bin/env pwsh

param (
    [Parameter(ValueFromPipeline=$True,Mandatory=$True,Position=0)]
    [String]$project,
    [Parameter(ValueFromPipeline=$True,Mandatory=$True,Position=1)]
    [String]$buildDefinitionId,
    [Parameter(ValueFromPipeline=$True,Mandatory=$False,Position=1)]
    [String]$organisation = "yourowndefault",
    [Parameter(ValueFromPipeline=$True,Mandatory=$True,Position=1)]
    #mounted secret or other secure file path:
    [String]$pat_token_file
)

$pat = Get-Content $pat_token_file

# Base64-encode the token
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))

# Get last completed build
$uri = "https://dev.azure.com/$organisation/$project/_apis/build/builds?definitions=$buildDefinitionID&statusFilter=completed&\$top=1&api-version=7.1"

$response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

# Check if there is a completed build
if ($response.value.Count -gt 0) {
    $lastBuild = $response.value[0]
    $buildId = $lastBuild.id
    $finishTime = $lastBuild.finishTime
    $buildURL = $lastBuild.url
    $buildStatus = $lastBuild.result


    Write-Output "Last build ID: $buildId"
    Write-Output "Finish Time: $finishTime"
    Write-Output "Last build status: $buildStatus"
    Write-Output "Build URL: $buildURL"

    if ($buildStatus -eq "failed"){
        $returnCode=2
    }
    if ($buildStatus -eq "succeeded"){
        $returnCode=0
    }

} else {
    Write-Output "No completed builds found."
    $returnCode=1
}

# Uncomment to debug exit code
#$returnCode

exit ($returnCode)
