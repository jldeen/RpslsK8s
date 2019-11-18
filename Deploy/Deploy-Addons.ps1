Param(
    [parameter(Mandatory=$true)][string]$resourceGroup,
    [parameter(Mandatory=$true)][string]$location,
    [parameter(Mandatory=$true)][string]$subscription="",
    [parameter(Mandatory=$true)][string]$clientId,
    [parameter(Mandatory=$true)][string]$password,
    [parameter(Mandatory=$true)][string]$tenant,
    [parameter(Mandatory=$false)][string]$tag="latest",
    [parameter(Mandatory=$false)][bool]$deployGlobalSecret=$false
)

$gValuesFile="configFile.yaml"

# Get AKS name
Write-Host "Retrieving Aks Name" -ForegroundColor Yellow
$aksName = $(az aks list -g $resourceGroup -o json | ConvertFrom-Json).name
Write-Host "The name of your AKS: $aksName" -ForegroundColor Yellow

#Get AKS credentials
Write-Host "Retrieving credentials" -ForegroundColor Yellow
az aks get-credentials -n $aksName -g $resourceGroup

if ($deployGlobalSecret) {
    # Deploys the global secret to access keyvault. Secret can also be installed
    # as part of game-api chart
    kubectl create secret generic game-api-kv --from-literal clientid=$clientId --from-literal clientsecret=$password --type=azure/kv
}

# Set up Dev Spaces

### TODO - TRY TO MAKE WORK UNATTENDED 
# WARNING: Installing Dev Spaces commands...
# WARNING: A separate window will open to guide you through the installation process.

# Write-Host "Setting up Azure Dev Spaces for AKS: $aksName"
# & ./Setup-Dev-Spaces.ps1 -resourceGroup $resourceGroup -aksName $aksName -rootSpace default

# # Generate Config
# $gValuesLocation=$(./Join-Path-Recursively.ps1 "..","helm","__values",$gValuesFile)
# & ./Generate-Config.ps1 -resourceGroup $resourceGroup -outputFile $gValuesLocation
# if (-not $?) { Pop-Location; Pop-Location; exit 1 }

# Build an Push
# & ./Build-Push.ps1 -resourceGroup $resourceGroup -dockerTag $tag
# if (-not $?) { Pop-Location; Pop-Location; exit 1 }

# Deploy images in AKS
$needToDeployKvSecret= -not $deployGlobalSecret
$gValuesLocation=$(./Join-Path-Recursively.ps1 "__values", $gValuesFile)
& ./Deploy-Images-Aks.ps1 -kvPassword $password -aksName $aksName -resourceGroup $resourceGroup -charts "*" -valuesFile $gValuesLocation -tag $tag -deployKvSecret $needToDeployKvSecret

Pop-Location
Pop-Location