param(
    [string]$ApiPath = (Join-Path $PSScriptRoot "..\..\rescueradio-api"),
    [string]$WebPath = (Join-Path $PSScriptRoot "..\..\rescueradio-web")
)

$ErrorActionPreference = "Stop"

$apiDirectory = (Resolve-Path $ApiPath).Path
$webDirectory = (Resolve-Path $WebPath).Path

Write-Host "Building rescueradio-api:local from $apiDirectory"
docker build -t rescueradio-api:local $apiDirectory

Write-Host "Building rescueradio-web:local from $webDirectory"
docker build -t rescueradio-web:local $webDirectory
