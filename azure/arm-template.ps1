<#
 .SYNOPSIS
    Deploys a template to Azure
 .DESCRIPTION
    Deploys an Azure Resource Manager template
 .PARAMETER subscriptionId
    The subscription id where the template will be deployed.
 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.
 .PARAMETER location
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.
 .PARAMETER deploymentName
    The deployment name.
 .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.
 .PARAMETER parametersFilePath
    Optional, path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.
#>

$json = (Get-Content -Raw -path './env.json' | Out-String | ConvertFrom-Json)

$subscriptionId = $json.subscriptionId
$resourceGroupName = $json.resourceGroupName
$location = $json.location
$deploymentName = $json.deploymentName
$templateFilePath = $json.templateFilePath
$parametersFilePath = $json.parametersFilePath

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
      [string]$ResourceProviderNamespace
    )
    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# sign in
# Write-Host "Logging in...";
# Login-AzAccount;

# select subscription
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzSubscription -SubscriptionID $subscriptionId;

if(Test-Path $parametersFilePath) {
  Write-Host "Validating Template"
  $TestResult = Test-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile $templateFilePath `
    -TemplateParameterFile $parametersFilePath;
  $TestResultCode = ($TestResult).Code;

  if ($TestResultCode -eq 'InvalidTemplate') {
    Write-Host "Template is Invalid"
    $TestResult
    Break;
  }
  Write-Host "Template is Valid"
}

# Register RPs
$resourceProviders = @("microsoft.storage","microsoft.network","microsoft.compute","microsoft.storage");
if($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
      RegisterRP($resourceProvider);
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzResourceGroup `
  -Name $resourceGroupName `
  -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if(!$location) {
      $location = Read-Host "location";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$location'";
    New-AzResourceGroup `
      -Name $resourceGroupName `
      -Location $location
}
else{
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# Start the deployment
Write-Host "Starting deployment...";
if(Test-Path $parametersFilePath) {
  Write-Host "From parameters"
  New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile $templateFilePath `
    -TemplateParameterFile $parametersFilePath;
} else {
  Write-Host "Not from parameters"
  New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile $templateFilePath;
}
