$json = (Get-Content -Raw -path './env.json' | Out-String | ConvertFrom-Json)
$vmName = $json.vmName
$resourceGroupName = $json.resourceGroupName
$location = $json.location
$imageName = $json.imageName

Stop-AzVM `
  -ResourceGroupName $resourceGroupName `
  -Name $vmName `
  -Force

write-output "Stopping VM"
$vm = Get-AzVM `
  -ResourceGroupName $resourceGroupName `
  -Name $vmName `
  -status
$state = $vm.Statuses[1].Code

While ($state -ne "PowerState/deallocated")
{
  Start-Sleep -Seconds 60
  write-output "VM state: $($state), waiting to be stopped"
  $vm = Get-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Name $vmName `
    -status
  $state = $vm.Statuses[1].Code
}

write-output "Generalizing VM..."
Set-AzVm `
  -ResourceGroupName $resourceGroupName `
  -Name $vmName `
  -Generalized

$diskState = (Get-AzVm -ResourceGroupName $resourceGroupName -Name $vmName).StorageProfile.OsDisk
write-output "Disk state: $($diskState)"
$vm = Get-AzVM `
  -ResourceGroupName $resourceGroupName `
  -Name $vmName `
  -status
$state = $vm.Statuses[0].Code

While ($state -ne "OSState/generalized")
{
  Start-Sleep -Seconds 60
  write-output "OSState: $($state), waiting to be generalized"
  $vm = Get-AzVM `
    -ResourceGroupName $resourceGroupName `
    -Name $vmName `
    -status
  $state = $vm.Statuses[0].Code
}

$vm = Get-AzVM `
  -Name $vmName `
  -ResourceGroupName $resourceGroupName

$image = New-AzImageConfig `
  -Location $location `
  -SourceVirtualMachineId $vm.Id

New-AzImage `
  -Image $image `
  -ImageName $imageName `
  -ResourceGroupName $resourceGroupName

# Removing VM and Counterparts
Remove-AzVm `
  -ResourceGroupName $resourceGroupName `
  -Name $vmName `
  -Force

Remove-AzNetworkInterface `
  -ResourceGroup $resourceGroupName `
  -Name $vmName"24" `
  –Force

Get-AzDisk `
  -ResourceGroupName $resourceGroupName `
  -DiskName $vm.StorageProfile.OSDisk.Name `
  | Remove-AzDisk -Force

Get-AzVirtualNetwork `
  -ResourceGroup $resourceGroupName `
  -Name $vmName"-vnet" `
  | Remove-AzVirtualNetwork -Force

Get-AzNetworkSecurityGroup `
  -ResourceGroup $resourceGroupName `
  -Name $vmName"-nsg" `
  | Remove-AzNetworkSecurityGroup -Force

Get-AzPublicIpAddress `
  -ResourceGroup $resourceGroupName `
  -Name $vmName"-ip" `
  | Remove-AzPublicIpAddress -Force
