# Azure Hosted Agent

This project generates a windows virtual machine with it's counterparts (network, disk, ip, ...) through the Azure Resource Manager template.  A custom extension built into the template downloads the azure agent onto the vm then runs sysprep, generalizes it, then shuts it down.  The build pipeline when setup should run an additional script to create an image from the vm and delete the vm and counterparts used to create it.

## Getting Started

### Prequisites
- Powershell (Manual run only)
- Az Powershell Module (Manual run only)
- Azure Account and Subscription

### Manually running scripts
make sure env.json exists and filled out
```
pwsh ./azure/scripts/upload-ext-scripts.ps1
```
```
pwsh ./azure/arm-template.ps1
```
```
pwsh ./azure/scripts/create-image-from-vm.ps1
```

### Authors
- Clement Choi
- Beda Tse

### Acknowledgments
