$json = (Get-Content -Raw -path './env.json' | Out-String | ConvertFrom-Json)
$resourceGroupName = $json.resourceGroupName
$location = $json.location
$storageAccountName = $json.storageAccountName
$containerName = $json.containerName # The name of the Blob container to be created.

New-AzResourceGroup -Name $resourceGroupName -Location $location

$storageAccount = Get-AzStorageAccount `
  -ResourceGroupName $resourceGroupName `
  -Name $storageAccountName;

write-output $storageAccount.ProvisioningState
if (!$storageAccount.Id -and $storageAccount.ProvisioningState -ne 'Running') {
  # Create a storage account
  write-output "in"
  $storageAccount = New-AzStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $storageAccountName `
    -Location $location `
    -SkuName "Standard_LRS"

  $context = $storageAccount.Context
  # Create a container
  New-AzStorageContainer -Name $containerName -Context $context
}
write-output "past"

$context = $storageAccount.Context

$templateFiles = Get-ChildItem -Path './vm-ext-scripts'

foreach ($template in $templateFiles) {
  $fileName = $template.Name
  # Upload the linked template
  $blob = Set-AzStorageBlobContent `
    -Container $containerName `
    -File "$(Split-Path $MyInvocation.MyCommand.Path)/../../vm-ext-scripts/$($fileName)" `
    -Blob $fileName `
    -Context $context

  # Generate a SAS token
  $templateURI = New-AzStorageBlobSASToken `
    -Context $context `
    -Container $containerName `
    -Blob $fileName `
    -Permission r `
    -ExpiryTime (Get-Date).AddHours(8.0) `
    -FullUri

  echo "You need the following values later in the tutorial:"
  echo "Resource Group Name: $resourceGroupName"
  echo "Linked template URI with SAS token: $templateURI"
}
